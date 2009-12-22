require 'multipart_post'


# doesn't work, breaks fixture loading
#ActionController::Integration::Session.class_eval do
#  include MultipartUpload
#end
#
# instead, do 
#   sess.extend(MultipartUpload)
# with your integration testing session
