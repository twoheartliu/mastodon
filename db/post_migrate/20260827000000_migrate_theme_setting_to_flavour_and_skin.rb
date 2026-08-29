# frozen_string_literal: true

class MigrateThemeSettingToFlavourAndSkin < ActiveRecord::Migration[8.1]
  DEFAULT_FLAVOUR = 'mastodon-ui'

  def up
    safety_assured do
      # User preferences live in a text column holding a JSON document
      # (serialized via UserSettingsSerializer): carry `theme` over to
      # `skin` verbatim (skin names intentionally match legacy theme
      # names), tag the default flavour, and drop the legacy key.
      execute <<~SQL.squish
        UPDATE users
        SET settings = ((settings::jsonb || '{"flavour":"mastodon-ui"}'::jsonb || jsonb_build_object('skin', settings::jsonb->'theme')) - 'theme')::text
        WHERE settings IS NOT NULL
          AND settings != ''
          AND settings::jsonb ? 'theme'
          AND settings::jsonb->>'theme' IS NOT NULL
      SQL

      # Site-level defaults live as YAML-serialized rows (`Setting#value`
      # encodes with .to_yaml): decode the legacy var and mirror it onto
      # the new pair. The legacy row is kept for rollback reference.
      site_theme = select_value("SELECT value FROM settings WHERE var = 'theme'")
      if site_theme.present?
        skin = YAML.safe_load(site_theme)
        upsert_setting('flavour', DEFAULT_FLAVOUR)
        upsert_setting('skin', skin)
      else
        upsert_setting('flavour', DEFAULT_FLAVOUR)
      end
    end
  end

  def down
    safety_assured do
      execute <<~SQL.squish
        UPDATE users
        SET settings = ((settings::jsonb || jsonb_build_object('theme', settings::jsonb->'skin')) - 'skin' - 'flavour')::text
        WHERE settings IS NOT NULL
          AND settings != ''
          AND settings::jsonb ? 'skin'
      SQL

      skin_row = select_value("SELECT value FROM settings WHERE var = 'skin'")
      if skin_row.present?
        theme = YAML.safe_load(skin_row)
        upsert_setting('theme', theme)
        execute "DELETE FROM settings WHERE var = 'skin'"
      end
    end
  end

  private

  def upsert_setting(var, value)
    encoded = quote(value.to_yaml)

    execute <<~SQL.squish
      INSERT INTO settings (var, value, created_at, updated_at)
      VALUES (#{quote(var)}, #{encoded}, NOW(), NOW())
      ON CONFLICT (var) DO UPDATE SET value = EXCLUDED.value, updated_at = NOW()
    SQL
  end
end
