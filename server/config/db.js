process.env.DATABASE_URL =
  `${process.env.DATABASE_URL}?ssl=no-verify` ||
  "postgres://postgres@localhost:5432/xrn";