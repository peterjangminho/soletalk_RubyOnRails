module Voice
  class ContextFilesController < ApplicationController
    before_action :authenticate_user!

    def create
      file = params[:file]

      if file.blank?
        render json: { status: "error", message: "No file provided" }, status: :unprocessable_entity
        return
      end

      current_user.uploaded_files.attach(file)

      render json: { status: "ok", filename: file.original_filename }
    end
  end
end
