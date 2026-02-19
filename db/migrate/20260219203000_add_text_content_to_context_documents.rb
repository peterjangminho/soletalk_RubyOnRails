class AddTextContentToContextDocuments < ActiveRecord::Migration[8.1]
  def change
    add_column :context_documents, :text_content, :text, null: false, default: ""
    add_column :context_documents, :text_format, :string, null: false, default: "plain"
    add_index :context_documents, :text_format
  end
end
