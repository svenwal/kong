return {
  postgres = {
    up = [[
      DO $$
      BEGIN
        ALTER TABLE IF EXISTS ONLY keyauth_credentials ADD tags TEXT[];
      EXCEPTION WHEN DUPLICATE_COLUMN THEN
        -- Do nothing, accept existing state
      END$$;

      DO $$
      BEGIN
        CREATE INDEX IF NOT EXISTS keyauth_tags_idex_tags_idx ON keyauth_credentials USING GIN(tags);
      EXCEPTION WHEN UNDEFINED_COLUMN THEN
        -- Do nothing, accept existing state
      END$$;

      DROP TRIGGER IF EXISTS keyauth_sync_tags_trigger ON keyauth_credentials;

      DO $$
      BEGIN
        CREATE TRIGGER keyauth_sync_tags_trigger
        AFTER INSERT OR UPDATE OF tags OR DELETE ON keyauth_credentials
        FOR EACH ROW
        EXECUTE PROCEDURE sync_tags();
      EXCEPTION WHEN UNDEFINED_COLUMN OR UNDEFINED_TABLE THEN
        -- Do nothing, accept existing state
      END$$;


      DO $$
      BEGIN
        ALTER TABLE IF EXISTS ONLY "keyauth_credentials" ADD COLUMN "secret" TEXT;
      EXCEPTION WHEN DUPLICATE_COLUMN OR UNDEFINED_TABLE THEN
        -- Do nothing, accept existing state
      END$$;
    ]],
  },
  cassandra = {
    up = [[
      ALTER TABLE keyauth_credentials ADD tags set<text>;


      ALTER TABLE "keyauth_credentials" ADD "secret" text;
      CREATE INDEX IF NOT EXISTS ON keyauth_credentials(secret);
    ]],
  }
}
