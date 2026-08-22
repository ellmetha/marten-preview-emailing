module MartenPreviewEmailing
  class PreviewEmail
    # A reference to an email attachment stored on disk.
    class AttachmentRef
      include JSON::Serializable
      include Marten::Template::Object

      getter filename : String
      getter path : String

      def initialize(@filename : String, @path : String)
      end

      template_attributes :filename, :path
    end
  end
end
