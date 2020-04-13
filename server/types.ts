import { Request } from 'express';
import { IncomingMessage } from 'http';

export interface UserRequest extends Request {
  user: any
}

export interface UserIncomingMessage extends IncomingMessage {
  user: any
}
