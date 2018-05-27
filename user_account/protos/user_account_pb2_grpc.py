# Generated by the gRPC Python protocol compiler plugin. DO NOT EDIT!
import grpc

from . import user_account_pb2 as user__account__pb2


class UserAccountStub(object):
  # missing associated documentation comment in .proto file
  pass

  def __init__(self, channel):
    """Constructor.

    Args:
      channel: A grpc.Channel.
    """
    self.Signup = channel.unary_unary(
        '/UserAccount.UserAccount/Signup',
        request_serializer=user__account__pb2.SignupRequest.SerializeToString,
        response_deserializer=user__account__pb2.UserAccountReply.FromString,
        )
    self.Signin = channel.unary_unary(
        '/UserAccount.UserAccount/Signin',
        request_serializer=user__account__pb2.SigninRequest.SerializeToString,
        response_deserializer=user__account__pb2.UserAccountReply.FromString,
        )
    self.ChangePhone = channel.unary_unary(
        '/UserAccount.UserAccount/ChangePhone',
        request_serializer=user__account__pb2.ChangePhoneRequest.SerializeToString,
        response_deserializer=user__account__pb2.UserAccountReply.FromString,
        )
    self.GetUserUUID = channel.unary_unary(
        '/UserAccount.UserAccount/GetUserUUID',
        request_serializer=user__account__pb2.GetUserUUIDRequest.SerializeToString,
        response_deserializer=user__account__pb2.GetUserUUIDReplay.FromString,
        )


class UserAccountServicer(object):
  # missing associated documentation comment in .proto file
  pass

  def Signup(self, request, context):
    """Gandalf <-> Gondor <-> UserAccount
    """
    context.set_code(grpc.StatusCode.UNIMPLEMENTED)
    context.set_details('Method not implemented!')
    raise NotImplementedError('Method not implemented!')

  def Signin(self, request, context):
    # missing associated documentation comment in .proto file
    pass
    context.set_code(grpc.StatusCode.UNIMPLEMENTED)
    context.set_details('Method not implemented!')
    raise NotImplementedError('Method not implemented!')

  def ChangePhone(self, request, context):
    # missing associated documentation comment in .proto file
    pass
    context.set_code(grpc.StatusCode.UNIMPLEMENTED)
    context.set_details('Method not implemented!')
    raise NotImplementedError('Method not implemented!')

  def GetUserUUID(self, request, context):
    # missing associated documentation comment in .proto file
    pass
    context.set_code(grpc.StatusCode.UNIMPLEMENTED)
    context.set_details('Method not implemented!')
    raise NotImplementedError('Method not implemented!')


def add_UserAccountServicer_to_server(servicer, server):
  rpc_method_handlers = {
      'Signup': grpc.unary_unary_rpc_method_handler(
          servicer.Signup,
          request_deserializer=user__account__pb2.SignupRequest.FromString,
          response_serializer=user__account__pb2.UserAccountReply.SerializeToString,
      ),
      'Signin': grpc.unary_unary_rpc_method_handler(
          servicer.Signin,
          request_deserializer=user__account__pb2.SigninRequest.FromString,
          response_serializer=user__account__pb2.UserAccountReply.SerializeToString,
      ),
      'ChangePhone': grpc.unary_unary_rpc_method_handler(
          servicer.ChangePhone,
          request_deserializer=user__account__pb2.ChangePhoneRequest.FromString,
          response_serializer=user__account__pb2.UserAccountReply.SerializeToString,
      ),
      'GetUserUUID': grpc.unary_unary_rpc_method_handler(
          servicer.GetUserUUID,
          request_deserializer=user__account__pb2.GetUserUUIDRequest.FromString,
          response_serializer=user__account__pb2.GetUserUUIDReplay.SerializeToString,
      ),
  }
  generic_handler = grpc.method_handlers_generic_handler(
      'UserAccount.UserAccount', rpc_method_handlers)
  server.add_generic_rpc_handlers((generic_handler,))