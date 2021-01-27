ALTER TABLE wallet
ALTER COLUMN addr SET DATA TYPE text USING encode(addr, 'escape');