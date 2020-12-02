import * as jwks from 'jwks-rsa';
import * as jwt from 'express-jwt';

export default function getJwt(credentialsRequired: boolean): jwt.RequestHandler {
  return jwt({
    secret: jwks.expressJwtSecret({
      cache: true,
      rateLimit: true,
      jwksRequestsPerMinute: 5,
      jwksUri: 'https://regen-network-registry.auth0.com/.well-known/jwks.json'
    }),
    credentialsRequired,
    audience: 'https://regen-registry-server.herokuapp.com/',
    issuer: 'https://regen-network-registry.auth0.com/',
    algorithms: ['RS256']
  });
}
