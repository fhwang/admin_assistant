module Admin::Images2Helper
  def path_html_for_index(image)
    url = 'http://' + request.host_with_port + image.image.url
    text_field_tag(
      image.id, url, :onclick => "javascript:this.focus(); this.select();"
    )
  end
end
