require 'capybara'
require 'faraday'

class Site < ApplicationRecord
  has_many :pages
  def crawl!
    save_and_visit_links('/', nil, false, layer=0)
  end
  def save_and_visit_links(path, from_page_id, by_redirection=false, layer)
    sleep 1
    logger.info "layer = " + layer.to_s
    uri = self.url + path
    conn = Faraday::Connection.new(:url =>URI.encode( uri))
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
      page_id = self.pages.create!(
        path: path,
        active: true,
        redirect_to: nil,
        title: title,
        h1: h1,
        empty_contents: empty_contents,
        redirected_page_id: nil
      ).id

      logger.info "created page_id = " + page_id.to_s
      LinkFromTo.create!(from_page_id: from_page_id, to_page_id: page_id, by_redirection: false) if from_page_id && page_id
      Capybara.string(res.body).all('a').map{|a| a['href'] }.reject{|t| t.nil? || t.empty? }.each do |link_path|
        link_path = strip_domain_if_same_domain(link_path)
        link_path = adjust_path(link_path, from_page_id)
        if is_target_site?(link_path)
          logger.info "DEBUGINFO: layer = " + layer.to_s + ", from = #{from_page_id.to_s}, to = #{link_path}"
          save_and_visit_links(link_path, page_id, false, layer+1) if is_html_link?(link_path)
        end
      end
    elsif res.status.in?([301, 302, 303])
      redirected_path = URI.parse(res.headers['location']).respond_to?(:requst_uri) ? 
        URI.parse(res.headers['location']).requst_uri : URI.parse(res.headers['location']).path
      redirected_path = strip_domain_if_same_domain(redirected_path)
      redirected_path = adjust_path(redirected_path, from_page_id)

      redirected_page_id = pages.by_path(redirected_path).first.try(:id)
      if redirected_page_id == nil
        #まだ来ていないので
        #リダイレクトされているという情報のみ書き込む
        redirected_page_id = pages.create!(
          path: path,
          active: false,
          redirect_to: redirected_path,
          title: nil,
          h1: nil,
          empty_contents: true,
          redirected_page_id: nil
        ).id
        if is_target_site?(redirected_path)
          LinkFromTo.create!(from_page_id: from_page_id, to_page_id: page_id, by_redirection: true) if from_page_id && page_id
          logger.info "DEBUGINFO: layer = " + layer.to_s + ", from = #{from_page_id.to_s}, to(redirected) = #{redirected_path}"
          save_and_visit_links(redirected_path, page_id, true, layer+1) if  is_html_link?(redirected_path)
        end
      else
        #既にこのリダイレクト先が登録されていれば探索しない
        #fromtoのみ書き込む
        if from_page_id && redirected_page_id && LinkFromTo.where(from_page_id: from_page_id, to_page_id: redirected_page_id).blank?
          LinkFromTo.create!(from_page_id: from_page_id, to_page_id: redirected_page_id, by_redirection: true)
        end
      end
    elsif res.status.in?([404, 422, 403])
        page_id = pages.find_or_create_by(
        path: path,
        active: false,
        title: nil,
        h1: nil,
        empty_contents: true,
        redirected_page_id: nil,
        status_code: res.status.to_s
      ).id 
      if from_page_id && page_id && LinkFromTo.where(from_page_id: from_page_id, to_page_id: page_id).blank?
        LinkFromTo.create!(from_page_id: from_page_id, to_page_id: page_id, by_redirection: false)
      end
    else
      raise StandardError, "unsupport status:" + res.status.to_s + ", path: " + path
    end
  end
  def is_target_site?(path)
    #path = path.gsub(/\?.*/,'')
    #host = URI.parse(path).host
    host = Addressable::URI.parse(path).host
    if host.in?([self.domain, nil])
      return false if Addressable::URI.parse(path).extname.in?(%w(.jpg .jpeg .JPG .JPEG ))
      return false if  path =~ %r!/column/.*!
      return false if  path =~ %r!/reservation/sp_reservation_popup\.php.*!
      return false if path =~ %r!select_day=\d+.*!
      return false if path =~ %r!/event/eventInformartion.*!
      return false if  path =~ %r!/informartion/Informartion.*!
      return false if  path =~ %r!/flow/trial_lp.*!
      return false if path =~ %r!^javascript:!
      if unvisited_page?(path)
        logger.info path + " is targetable"
        return true 
      end
    end
    return false
  end
  def adjust_path(path, from_page_id)
    #ページ内リンク除外
    path = path.gsub(/#.*/,'')
    #path = path.gsub(%r!\.+!,'')
    #最後の/をとる
    path = path.gsub(%r!/$!,'')
    if path  =~ %r!^\.{1}/!
      #./index.phpの先頭の.をとる
      path = path.gsub(%r!^\.{1}!,'')
    end
    if path =~  %r!^\.\./! && from_page_id
      #相対パス対策 ../index.php
      if from_page_path = Page.find(from_page_id).path
        joined_path = from_page_path + path
        joined_path = Addressable::URI.parse(joined_path).normalize!.path
        return joined_path
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
      if is_target_site?(path) && from_page_path = Page.where(id: from_page_id).first.try(:path)
        joined_path = from_page_path + "/../#{path}"
        joined_path = Addressable::URI.parse(joined_path).normalize!.path
        return joined_path
      end
    end
    path
  end
  private
  def unvisited_page?(path)
    self.pages.by_path(path).blank?
  rescue TypeError
    abort path.to_s
  end
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
