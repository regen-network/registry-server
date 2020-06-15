process.env.DATABASE_URL =
  `${process.env.DATABASE_URL}?ssl=true&sslrootcert=../config/rds-combined-ca-bundle.pem` ||
  "postgres://postgres@localhost:5432/xrn";