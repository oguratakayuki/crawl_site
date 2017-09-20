require 'capybara'
require 'faraday'
require 'csv'

class Site < ApplicationRecord
  has_many :pages
  def crawl!(device)
    save_and_visit_links('/', nil, layer=0, device, by_redirection=false)
  end
  def save_and_visit_links(path, from_page_id, layer, device, by_redirection)
    sleep 1
    uri = self.url + path
    conn = Faraday::Connection.new(:url =>URI.encode( uri))
    conn.headers[:user_agent] = 'Mozilla/5.0 (iPhone; CPU iPhone OS 10_2_1 like Mac OS X) AppleWebKit/602.4.6 (KHTML, like Gecko) Version/10.0 Mobile/14D27 Safari/602.1' if device == 'mobile'
    begin
      res = conn.get URI.encode(path)
    rescue Faraday::ConnectionFailed
      abort path
    end
    if res.status == 200
      logger.info "status = " + res.status.to_s

      empty_contents = res.body.size == 0
      title = Capybara.string(res.body).title
      h1 = Capybara.string(res.body).all('h1').first.try(:text) || ''

      page_id = save_page(path, is_active=true, redirect_to=nil, title, h1, empty_contents, res.body.size, res.status.to_s, from_page_id, by_redirection, device)
      Capybara.string(res.body).all('a').map{|a| a['href'] }.reject{|t| t.nil? || t.empty? }.each do |link_path|
        link_path = adjust_path(link_path, from_page_id, device)
        if is_target_site?(link_path, device)
          logger.info "DEBUGINFO1: layer = " + layer.to_s + ", from = #{from_page_id.to_s}, to = #{link_path}, device = #{device}"
          save_and_visit_links(link_path, page_id, layer+1, device, by_redirection) if is_html_link?(link_path)
        end
      end
    elsif res.status.in?([301, 302, 303])
      redirected_path = URI.parse(res.headers['location']).respond_to?(:requst_uri) ? 
        URI.parse(res.headers['location']).requst_uri : URI.parse(res.headers['location']).path
      redirected_path = adjust_path(redirected_path, from_page_id, device)
      #まず今のページ情報を保存
      page_id = save_page(path, is_active=false, redirect_to=redirected_path, title=nil, h1=nil, empty_contents=true, size=nil, res.status.to_s, from_page_id, by_redirection, device)
      #リダイレクト先の情報を取得し
      if unvisited_page?(redirected_path, device)
        #まだアクセスしてない
        if is_target_site?(redirected_path, device)
          #対象かどうか
          logger.info "DEBUGINFO2: layer = " + layer.to_s + ", from = #{from_page_id.to_s}, original to =#{path}, to(redirected) = #{redirected_path}, device = #{device}"
          return if redirected_path == path
          save_and_visit_links(redirected_path, page_id, layer+1, device, by_redirection) if  is_html_link?(redirected_path)
        end
      else
        #すでにアクセスがあれば
        #LinkFromToにこのページからリダイレクト先への情報を書き込むだけ
        redirected_page_id = pages.by_path(redirected_path).first.try(:id)
        LinkFromTo.create!(from_page_id: page_id, to_page_id: redirected_page_id, by_redirection: true)
      end
    elsif res.status.in?([404, 422, 403])
      page_id = save_page(path, is_active=false, redirect_to=nil, title=nil, h1=nil, empty_contents=true, size=nil, res.status.to_s, from_page_id, by_redirection, device)
    else
      raise StandardError, "unsupport status:" + res.status.to_s + ", path: " + path
    end
  end

  def save_page(path, is_active=true, redirect_to=nil, title, h1, empty_contents, size, status_code, from_page_id, by_redirection, device)
    page = self.pages.find_or_create_by!(
      path: path,
      active: is_active,
      redirect_to: redirect_to,
      title: title,
      h1: h1,
      empty_contents: empty_contents,
      redirected_page_id: nil,
      size: size,
      status_code: status_code,
      device_type: device
    )
    if from_page_id && page.id && LinkFromTo.where(from_page_id: from_page_id, to_page_id: page.id).blank?
      LinkFromTo.create!(from_page_id: from_page_id, to_page_id: page.id, by_redirection: by_redirection)
    end
    page.id
  end

  def is_target_site?(path, device)
    #path = path.gsub(/\?.*/,'')
    #host = URI.parse(path).host
    host = Addressable::URI.parse(path).host
    if host.in?([self.domain, nil])
      return false if Addressable::URI.parse(path).extname.in?(%w(.jpg .jpeg .JPG .JPEG .png .PNG ))
      #return false if  path =~ %r!/column/.*!
      return false if  path =~ %r!/reservation/sp_reservation_popup\.php.*!
      return false if path =~ %r!/member/outerSelectLogin\.php.*!
      return false if path =~ %r!select_day=\d+.*!
      return false if path =~ %r!mailto.*!
      return false if path =~ %r!tel:.*!
      #return false if path =~ %r!/event/eventInformartion.*!
      #return false if  path =~ %r!/informartion/Informartion.*!
      return false if  path =~ %r!/flow/trial_lp.*!
      return false if path =~ %r!^javascript:!
      if unvisited_page?(path, device)
        logger.info path + " is targetable"
        return true 
      end
    end
    return false
  end
  def adjust_path(path, from_page_id, device)
    logger.info "DEBUGINFO3: before link_path = #{path}"
    path = strip_domain_if_same_domain(path)
    #ページ内リンク除外
    path = path.gsub(/#.*/,'')
    #path = path.gsub(%r!\.+!,'')
    #最後の/をとる
    #path = path.gsub(%r!/$!,'')
    if path  =~ %r!^\.{1}/!
      #./index.phpの先頭の.をとる
      path = path.gsub(%r!^\.{1}!,'')
    end
    #もし拡張子がない,ディレクトリである時 #最後に/をつける
    if Addressable::URI.parse(path).extname.blank? && path[-1] != '/' && Addressable::URI.parse(path).query.blank?
      path = path + '/'
    end

    if path =~  %r!^\.\./!
      #相対パス対策 ../index.php
      if from_page_id && from_page_path = Page.find(from_page_id).path
        #"/lessonSchedule/?studio_id=23"みたいなパスからクエリを取り除く
        #from_page_path = Addressable::URI.parse(from_page_path).path
        #if  from_page_path.last != '/'
        #  #もし末尾が/hogeみたいな時は結合するとhoge../index.phpになってしまうので
        #  #hoge/../index.phpになるようにする
        #  from_page_path = from_page_path + '/'
        #end
        #joined_path = from_page_path + path
        #joined_path = Addressable::URI.parse(joined_path).normalize!.path
        #全部../../をとって、最後に先頭に/をつける
        path = "/" + path.gsub(%r!^[\.\./]+!,'')
        #logger.info "DEBUGINFO4: after from_page_path = #{from_page_path}, + path = #{path}, joined_path = #{joined_path}"
        #return joined_path
        return path
      else
        #一発目(index.php)はここに来る
        path = path.gsub(%r!^\.\.!,'')
        return path
      end
    end
    if path =~ %r!^\?.*! && from_page_id
      #いきなり？の時は前ページに対するクエリ
      if from_page_path = Page.find(from_page_id).path
        joined_path = from_page_path + path
        return joined_path
      end
    end
    if path =~ %r!^[^/]!
      #先頭に/がない「hoge.php」など相対パス
      if is_target_site?(path, device) && from_page_path = Page.where(id: from_page_id).first.try(:path)
        joined_path = from_page_path + "/../#{path}"
        joined_path = Addressable::URI.parse(joined_path).normalize!.path
        return joined_path
      end
    end
    path
  end
  def unvisited_page?(path, device)
    logger.info 'DDDD' + "path =!#{path}!, device=!#{device}!"
    ret = self.pages.by_path(path).by_device_type(device).blank?
    logger.info 'DDDD' + ret.to_s
    ret
  rescue TypeError
    abort path.to_s
  end

  def export(device_type)
    headers = %w(デバイス full_path リンク数 statuscode title h1 リダイレクト先)
    return csv_data = ::CSV.generate(headers: headers, write_headers: true, force_quotes: true) do |csv|
      pages.by_device_type(device_type.to_s).each do |page|
        csv <<
        [
          page.device_type,
          page.full_path,
          page.froms.size,
          page.status_code,
          page.title,
          page.h1,
          page.redirect_to
        ]
      end
    end
  end


  private
  def is_html_link?(path)
    if path =~ /mailto:/ || path =~ /tel:/
      false
    else
      true
    end
  end
  def strip_domain_if_same_domain(link_path)
    link_path = link_path.strip
    if Addressable::URI.parse(link_path).host == self.domain
      Addressable::URI.parse(link_path).request_uri 
    elsif Addressable::URI.parse(link_path).host == nil 
      Addressable::URI.parse(link_path).to_s
    else
      link_path
    end
  end
end
