class CreateContextDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :context_documents do |t|
      t.references :user, null: false, foreign_key: true
      t.string :filename, null: false
      t.string :content_type, null: false
      t.integer :byte_size, null: false, limit: 8
      t.string :source_checksum, null: false
      t.integer :chunk_count, null: false, default: 0
      t.integer :vector_count, null: false, default: 0
      t.string :ontology_object_id
      t.string :storage_mode, null: false, default: "embedding_metadata_vector"
      t.string :ingestion_status, null: false, default: "ingested"
      t.json :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :context_documents, :ingestion_status
    add_index :context_documents, :source_checksum
  end
end
