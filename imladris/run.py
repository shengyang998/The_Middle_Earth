import logging
from concurrent.futures import ThreadPoolExecutor
import time
from redis import StrictRedis, ConnectionPool

import grpc

from basicconfig import get_config

conf = get_config("config.conf")

from protos import imladris_pb2, imladris_pb2_grpc

logging.basicConfig(format=conf.LOG_FORMAT, level=conf.LOG_LEVEL, datefmt=conf.LOG_DATE_FORMAT)
logger = logging.getLogger(__name__)


def get_ip_port_from_grpc_context(context):
    addr = context.peer().split(':')
    ip, port = addr[1], addr[2]
    return ip, port


def get_ip_port_from_db_addr(dist_addr):
    from ast import literal_eval
    dist_addr = literal_eval(str(dist_addr, 'utf-8'))
    dist_ip = dist_addr['ip']
    dist_port = dist_addr['port']
    return dist_ip, dist_port


class DatabaseConfiguration:
    db = None

    @classmethod
    def __new__(cls, *args, **kwargs):
        if not hasattr(cls, 'instance'):
            cls.instance = super(DatabaseConfiguration, cls).__new__(cls)
        return cls.instance

    @classmethod
    def get_db(cls):
        if cls.db is None:
            cls.db = StrictRedis()
        return cls.db



def recall_msg(context):
    logger.info("Recall Msg received.")
    pass


def ping(context):
    logger.info("Ping received.")
    pass


def lovely_signal(sig, context):
    dispatcher = {
        0: ping,
        1: recall_msg
    }
    dispatcher[sig](context)
    return imladris_pb2.SignalReply(status_code=conf.STATUS_OK)


def sendto(source_uuid, dist_uuid, context):
    db = DatabaseConfiguration.get_db()
    dist_addr = db.get(dist_uuid)
    if dist_addr is not None:
        dist_ip, dist_port = get_ip_port_from_db_addr(dist_addr)
        return imladris_pb2.SendToReply(status_code=conf.STATUS_OK, dist_ip=dist_ip, dist_port=dist_port)
    else:
        return imladris_pb2.SendToReply(status_code=conf.STATUS_SENDING_FAILED, dist_ip='', dist_port='')


class ImladrisServicer(imladris_pb2_grpc.ImladrisServicer):

    def SendTo(self, request, context):
        source_uuid = request.source_uuid
        dist_uuid = request.dist_uuid
        source_ip, source_port = get_ip_port_from_grpc_context(context)
        # FIXME: how to send msg to objc client
        logger.info("Sending message from {0} to {1}".format(request.source_phone, request.dist_phone))
        return sendto(source_uuid, dist_uuid, context)

    def Signin(self, request, context):
        uuid = request.uuid  # FIXME: change phone to uuid
        ip, port = get_ip_port_from_grpc_context(context)
        db = DatabaseConfiguration.get_db()
        db.setex(uuid, conf.SIGNIN_EXPIRE_TIME, {'ip': ip, 'port': port})

    def Signal(self, request, context):
        logger.info("Get Signal: {0}".format(request.signal))
        uuid = request.uuid
        signal = request.signal
        msg = request.msg
        return lovely_signal(signal, context)


def start_server(port):
    server = grpc.server(ThreadPoolExecutor(max_workers=100))
    imladris_pb2_grpc.add_ImladrisServicer_to_server(servicer=ImladrisServicer(), server=server)
    # MARK: Secure server
    server.add_secure_port('0.0.0.0:{0}'.format(port), get_server_credentials())
    #server.add_insecure_port("[::]:{0}".format(port))
    logger.info("Starting gRPC server at {0}...".format(port))
    server.start()
    logger.info("gRPC server is started.")
    return server


def close(server):
    logger.info("Stopping the gRPC server...")
    server.stop(0)
    logger.info("gRCP server is stopped.")


def get_server_credentials():
    with open('./keys/imladris.key', 'rb') as f:
        private_key = f.read()
    with open('./keys/imladris.crt', 'rb') as f:
        certificate_chain = f.read()
    return grpc.ssl_server_credentials(((private_key, certificate_chain),))


def main():
    server = start_server(port=conf.IMLADRIS_PORT)
    try:
        while True:
            time.sleep(conf._ONE_DAY_IN_SECONDS)
    except KeyboardInterrupt:
        close(server)


if __name__ == "__main__":
    main()
