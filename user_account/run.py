import logging
from concurrent.futures import ThreadPoolExecutor
import time
from uuid import uuid4
from peewee import MySQLDatabase, Model, CharField

import grpc

from basicconfig import get_config

conf = get_config("config.conf")

from protos import user_account_pb2, user_account_pb2_grpc

logging.basicConfig(format=conf.LOG_FORMAT, level=conf.LOG_LEVEL, datefmt=conf.LOG_DATE_FORMAT)
logger = logging.getLogger(__name__)


def is_validated_signup(phone, name, validation_code):  # FIXME TODO: put these into Gondor
    # TODO: 1. phone <=> name
    # TODO: 2. phone <=> validation_code
    return True


def is_validated_signin(phone, validation_code):  # FIXME TODO: put these into Gondor
    # TODO: phone <=> validation_code
    return True


def is_validated_change_phone(phone, validation_code):  # FIXME TODO: put these into Gondor
    # TODO: phone <=> validation_code
    return True


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
            cls.db = MySQLDatabase(
                conf.DATABASE_NAME,
                host=conf.LOCAL_HOST,
                port=conf.DATABASE_PORT,
                user=conf.LOGIN_USERNAME,
                password=conf.LOGIN_PASSWORD,
                charset=conf.DATABASE_CHARSET)
            cls.db.connect()
        return cls.db


class BaseModel(Model):
    class Meta:
        database = DatabaseConfiguration.get_db()

        def __init__(self):
            # self.database = self.configure_db()
            logger.warning("self.database: {0}".format(self.database))


class Users(BaseModel):
    phone = CharField()
    name = CharField()
    uuid = CharField()


def signup(phone, name, validation_code, context):
    if is_validated_signup(phone=phone, name=name,
                           validation_code=validation_code):  # FIXME TODO: put these into Gondor
        uuid = str(uuid4())
        if Users(phone=phone, name=name, uuid=uuid).save() > 0:
            return user_account_pb2.UserAccountReply(status_code=conf.STATUS_OK, uuid=uuid)
        else:
            logger.error("!!! Database Error Occured !!!")
            return user_account_pb2.UserAccountReply(status_code=conf.STATUS_DBERROR)
    else:
        return user_account_pb2.UserAccountReply(status_code=conf.STATUS_FORBIDDEN)


def signin(phone, validation_code, context):
    if is_validated_signin(phone=phone, validation_code=validation_code):  # FIXME TODO: put these into Gondor
        uuid = Users.get(Users.phone == phone).uuid
        if uuid is not None:
            return user_account_pb2.UserAccountReply(status_code=conf.STATUS_OK, uuid=uuid)
        else:
            return user_account_pb2.UserAccountReply(status_code=conf.STATUS_DBERROR)
    else:
        return user_account_pb2.UserAccountReply(status_code=conf.STATUS_FORBIDDEN)


def change_phone(uuid, new_phone, validation_code, context):
    if is_validated_change_phone(phone=old_phone, validation_code=validation_code):  # FIXME TODO: put these into Gondor
        old_phone = Users.get(Users.uuid == uuid).phone
        try:
            query = Users.update(phone=new_phone).where(Users.phone == old_phone)
            if query.execute() > 0:
                return user_account_pb2.UserAccountReply(status_code=conf.STATUS_OK)
            else:
                logger.error(
                    "!!! Database UNABLE to find the USER !!!\n!!! This should never happen !!!\n!!! The system may be cracked !!!")
                return user_account_pb2.UserAccountReply(status_code=conf.STATUS_DBERROR)
        except:
            return user_account_pb2.UserAccountReply(status_code=conf.STATUS_DBERROR)
    else:
        return user_account_pb2.UserAccountReply(status_code=conf.STATUS_FORBIDDEN)


def get_user_uuid(uuid, dist_phone, context):
    try:
        dist_uuid = Users.get(Users.phone == dist_phone).uuid
    except:
        return user_account_pb2.GetUserUUIDReply(status_code=conf.STATUS_DBERROR, dist_uuid="")
    return user_account_pb2.GetUserUUIDReply(status_code=conf.STATUS_OK, dist_uuid=dist_uuid)


class UserAccountServicer(user_account_pb2_grpc.UserAccountServicer):

    # def __init__(self):
    #     pass

    def Signup(self, request, context):
        logger.info("User {0} is signing up.".format(request.phone))
        return signup(request.phone, request.name, request.validation_code, context)

    def Signin(self, request, context):
        logger.info("User {0} is signing in.".format(request.phone))
        return signin(request.phone, request.validation_code, context)

    def ChangePhone(selfs, request, context):
        logger.info("User {0} is changing phone.".format(request.old_phone))
        return change_phone(request.uuid, request.new_phone, request.validation_code, context)

    def GetUserUUID(self, request, context):
        logger.info("User {0} is getting UUID for user {1}.".format(request.uuid, request.dist_phone))
        return get_user_uuid(request.uuid, request.dist_phone, context)


def start_server(port):
    server = grpc.server(ThreadPoolExecutor(max_workers=1000))
    user_account_pb2_grpc.add_UserAccountServicer_to_server(servicer=UserAccountServicer(), server=server)
    server.add_secure_port('[::]:{0}'.format(port), get_server_credentials())
    logger.info("Starting gRPC server...")
    server.start()
    logger.info("gRPC server is started.")
    return server


def close(db, server):
    logger.info("Stopping the Database connection...")
    db.close()
    logger.info("Database is disconnected.")
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
    server = start_server(port=conf.USERACCOUNT_PORT)
    try:
        while True:
            time.sleep(conf._ONE_DAY_IN_SECONDS)
    except KeyboardInterrupt:
        close(DatabaseConfiguration.get_db(), server)


if __name__ == "__main__":
    main()
