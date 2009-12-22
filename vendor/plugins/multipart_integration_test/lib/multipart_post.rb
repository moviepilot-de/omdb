module MultipartPost

  def multipart_post(path, parameters = {})
    # boundary calc from http://wiki.rubyonrails.org/rails/pages/HowToSendAFileByPostMultipart
    boundary = Array::new(8){ "%2.2d" % rand(42) }.join('')
    body = multipart_requestify( parameters, boundary )
    body = body.flatten.map { |p| "--#{boundary}\r\n#{p}" }.join('') + "--#{boundary}--\r\n" if Array === body
    post path, body, { 'CONTENT_TYPE' => "multipart/form-data; boundary=#{boundary}" }
  end


  protected
    # Convert the given parameters to a request string. The parameters may
    # be a string, +nil+, or a Hash.
    def multipart_requestify(parameters, boundary, prefix=nil)
      if Hash === parameters
        return nil if parameters.empty?
        parameters.map { |k,v| 
          multipart_requestify(v, boundary, name_with_prefix(prefix, k)) 
        }
      elsif Array === parameters
        parameters.map { |v| 
          multipart_requestify(v, boundary, name_with_prefix(prefix, "")) 
        }
      elsif ActionController::TestUploadedFile === parameters
        file_to_multipart(prefix, parameters.original_filename, 
                          parameters.content_type, parameters.read)
      elsif parameters.nil? # use nil to mimic an empty file upload field
        file_to_multipart(prefix, '', 'application/octet-stream', '')
      elsif prefix.nil?
        parameters
      else
        text_to_multipart(prefix, parameters.to_s)
      end
    end

    # from http://www.realityforge.org/articles/2006/03/02/upload-a-file-via-post-with-net-http
    def text_to_multipart(key,value)
      #%{Content-Disposition: form-data; name="#{CGI::escape(key)}"\r\n\r\n#{value}\r\n}
      %{Content-Disposition: form-data; name="#{key}"\r\n\r\n#{value}\r\n}
    end

    def file_to_multipart(key,filename,mime_type,content)
      #%{Content-Disposition: form-data; name="#{CGI::escape(key)}"; filename="#{filename}"\r\nContent-Transfer-Encoding: binary\r\nContent-Type: #{mime_type}\r\n\r\n#{content}\r\n}
      %{Content-Disposition: form-data; name="#{key}"; filename="#{filename}"\r\nContent-Transfer-Encoding: binary\r\nContent-Type: #{mime_type}\r\n\r\n#{content}\r\n}
    end

end

