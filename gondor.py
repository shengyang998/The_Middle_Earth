import logging
from concurrent.futures import ThreadPoolExecutor, as_completed
import time
from uuid import uuid4, uuid5, NAMESPACE_URL
from redis import StrictRedis

import grpc

from py_protos import user_account_pb2, user_account_pb2_grpc, shadowfax_pb2, shadowfax_pb2_grpc, imladris_pb2, \
    imladris_pb2_grpc

from basicconfig import get_config

conf = get_config('config.conf')

logging.basicConfig(format=conf.LOG_FORMAT,
                    level=conf.LOG_LEVEL, datefmt=conf.LOG_DATE_FORMAT)
logger = logging.getLogger(__name__)


def get_trusted_crts(server_name):
    with open('./keys/{0}.crt'.format(server_name), 'rb') as f:
        trusted_certs = f.read()
    return trusted_certs

user_account_credentials = grpc.ssl_channel_credentials(root_certificates=get_trusted_crts("user_account"))
user_account_channel = grpc.secure_channel(conf.LOCAL_HOST + ':' + conf.USERACCOUNT_PORT, user_account_credentials)
imladris_credentials = grpc.ssl_channel_credentials(root_certificates=get_trusted_crts("imladris"))
imladris_channel = grpc.secure_channel(conf.LOCAL_HOST + ':' + conf.IMLADRIS_PORT, imladris_credentials)


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


def is_valid_user(uuid, token):
    db = DatabaseConfiguration.get_db()
    salt = db.get(uuid)
    if salt is not None and uuid5(NAMESPACE_URL, "{0}.{1}".format(uuid, salt)) == token:
        return True


def gondor():
    return '{"hello": "world"}'


def signup(phone, name, validation_code, context):
    # MARK: create stub
    stub_user_account = user_account_pb2_grpc.UserAccountStub(
        user_account_channel)
    # MARK: get `phone`, `name`, `validation_code` from client
    # make request to user account app
    response = stub_user_account.Signup(
        user_account_pb2.SignupRequest(phone=phone, name=name, validation_code=validation_code))
    logger.info("User {0} signup: {1}".format(phone,
                                              'SUCCESSFUL' if response.status_code == 200 else 'Error code: {0}'.format(
                                                  response.status_code)))
    return response


def signin(phone, validation_code, context):
    # TODO: add return uuid, token to the end
    stub_user_account = user_account_pb2_grpc.UserAccountStub(
        user_account_channel)
    channel_imladris = grpc.secure_channel(
        conf.LOCAL_HOST + ':' + conf.IMLADRIS_PORT)
    stub_imladris = imladris_pb2_grpc.ImladrisStub(channel_imladris)
    # create db
    db = DatabaseConfiguration.get_db()
    # make request to user account with phone
    response = stub_user_account.Signin(user_account_pb2.SigninRequest(
        phone=phone, validation_code=validation_code))
    salt = uuid4()
    db.set(response.uuid, salt)
    token = str(uuid5(NAMESPACE_URL, "{0}.{1}".format(response.uuid, salt)))
    logger.info("Generated token for user: {0}".format(response.uuid))
    if response.status_code == 200:
        # make request to imladrs with uuid
        resp = stub_imladris.Signin(
            imladris_pb2.SigninRequest(uuid=response.uuid))
        if resp.status_code == 200:
            logger.info("User {0} signin: {1}".format(phone,
                                                      'SUCCESSFUL' if response.status_code == 200 else 'Error code: {0}'.format(
                                                          response.status_code)))
        else:
            logger.error(
                "User signin failed. Error Code: {0}".format(resp.status_code))
    else:
        logger.info("User {0} signin: {1}".format(phone,
                                                  'SUCCESSFUL' if response.status_code == 200 else 'Error code: {0}'.format(
                                                      response.status_code)))
    return shadowfax_pb2.UserAccountReply(status_code=response.status_code, uuid=response.uuid,
                                          token=token)


def change_phone(uuid, token, new_phone, validation_code, context):
    # create stub
    stub_user_account = user_account_pb2_grpc.UserAccountStub(
        user_account_channel)
    if is_valid_user(uuid, token):
        # make request
        response = stub_user_account.ChangePhone(
            user_account_pb2.ChangePhoneRequest(uuid=uuid, new_phone=new_phone, validation_code=validation_code))
        logger.info("User {0} change_phone to {1} {2}".format(
            old_phone, new_phone,
            'SUCCESSFUL' if response.status_code == 200 else 'Error code: {0}'.format(response.status_code)))
        return response
    else:
        return user_account_pb2.UserAccountReply(status_code=conf.STATUS_FORBIDDEN, uuid="", token="")


def get_user_uuid(uuid, token, dist_phone, context):
    if is_valid_user(uuid, token):
        stub = user_account_pb2_grpc.UserAccountStub(user_account_channel)
        return stub.GetUserUUID(uuid=uuid, dist_phone=dist_phone)
    else:
        return user_account_pb2.GetUserUUIDReplay(status_code=conf.STATUS_FORBIDDEN, dist_uuid="")


def sent_to(uuid, token, dist_uuid):
    # create stub
    stub = imladris_pb2_grpc.ImladrisStub(imladris_channel)
    db = DatabaseConfiguration.get_db()
    salt = db.get(uuid)
    if salt is not None and uuid5(NAMESPACE_URL, "{0}.{1}".format(uuid, salt)) == token:
        # make erquest
        # FIXME: change dist_phone to dist_uuid
        response = stub.SendTo(uuid=uuid, dist_uuid=dist_uuid)
        return response
    else:
        return


def call_robot(uuid, token, robot_id):
    pass


class UserAccountServicer(shadowfax_pb2_grpc.UserAccountServicer):

    def Signup(self, request, context):
        logger.info("User {0} is signing up.".format(request.phone))
        return signup(request.phone, request.name, request.validation_code, context)

    def Signin(self, request, context):
        logger.info("User {0} is signing in.".format(request.phone))
        return signin(request.phone, request.validation_code, context)

    def ChangePhone(self, request, context):
        logger.info("User {0} is changing phone.".format(request.phone))
        return change_phone(request.uuid, request.token, request.new_phone, request.validation_code, context)

    def GetUserUUID(self, request, context):
        logger.info("User {0} is getting UUID for user {1}.".format(request.uuid, request.dist_phone))
        return get_user_uuid(request.uuid, request.token, request.dist_phone, context)


class ImladrisServicer(shadowfax_pb2_grpc.ImladrisServicer):
    # TODO: Imladris

    def SendTo(self, request, context):
        source_phone = request.source_uuid
        dist_phone = request.dist_phone
        logger.info("Sending message from {0} to {1} failed. User Not Yet Online.".format(
            source_phone, dist_phone))
        return sent_to(uuid, token, dist_uuid)

    def Signal(self, request, context):
        pass


class ValinorServicer(shadowfax_pb2_grpc.ValinorServicer):
    # TODO: Valinor

    def CallRobot(self, request, context):
        pass


def start_server(port):
    """start gRPC server for client

    Returns:
        [grpc.server] -- gRPC server
    """
    server = grpc.server(ThreadPoolExecutor(max_workers=conf.GRPC_MAX_WORKER))
    shadowfax_pb2_grpc.add_UserAccountServicer_to_server(
        servicer=UserAccountServicer(), server=server)
    shadowfax_pb2_grpc.add_ImladrisServicer_to_server(
        servicer=ImladrisServicer(), server=server)
    shadowfax_pb2_grpc.add_ValinorServicer_to_server(
        servicer=ValinorServicer(), server=server)
    # MARK: Secure server
    server.add_secure_port('[::]:{0}'.format(port), get_server_credentials())
    logger.info("Starting gRPC server...")
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
    return grpc.ssl_server_credentials(((private_key, certificate_chain,),))


def main():
    server = start_server(conf.GONDOR_PORT)
    try:
        while True:
            time.sleep(conf._ONE_DAY_IN_SECONDS)
    except KeyboardInterrupt:
        close(server)

if __name__ == '__main__':
    main()
