class ChangeDisputeResolutionToJsonb < ActiveRecord::Migration[7.2]
  def up
    return unless column_exists?(:disputes, :resolution)
    return if connection.columns(:disputes).find { |column| column.name == "resolution" }&.type == :jsonb

    change_column :disputes, :resolution, :jsonb,
      using: <<~SQL.squish,
        CASE
          WHEN resolution IS NULL OR btrim(resolution) = '' THEN '{"text":"","image_urls":[]}'::jsonb
          ELSE jsonb_build_object('text', resolution, 'image_urls', '[]'::jsonb)
        END
      SQL
      default: { "text" => "", "image_urls" => [] },
      null: false
  end

  def down
    return unless column_exists?(:disputes, :resolution)

    change_column :disputes, :resolution, :text,
      using: "resolution->>'text'",
      null: true
  end
end
