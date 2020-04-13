import { Request } from 'express';
import { IncomingMessage } from 'http';

interface User {
  sub?: string;
}

export interface UserRequest extends Request {
  user: User;
}

export interface UserIncomingMessage extends IncomingMessage {
  user: User;
}
