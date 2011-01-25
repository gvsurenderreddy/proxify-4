require 'httparty'

class ApplicationController < ActionController::Base
  before_filter :check_session_domain

  def catch_routes
    response = HTTParty.get(session[:domain] + "/" + params[:path])
    send_data(response, :type =>  response.headers["content-type"], :disposition  =>  'inline')
  end

  def proxify
    url = params[:url]
    url = "http://" + url if(url.index(/\b(?:https?:\/\/)\S+\b/) == nil)
    get_url(url)
    session[:domain] =  url.match(/\b(?:https?:\/\/)\S+\b/).to_s

    send_data(@response, :type =>  "xml", :disposition  =>  'inline') if @response_format == "xml"
  end

  def credentials
  end

  ############
  private
  ############

  def get_url(url)
    options = get_query_params
    @response = request.post? ? HTTParty.post(url, options) : HTTParty.get(url, options)
    @response_format = @response.headers["content-type"].split('/').last.split(';').first
    redirect_to :credentials if @response.code == 401
    @response =  @response_format == 'html' ? @response.html_safe : (@response_format == 'javascript' ? @response.to_json.html_safe : @response.to_xml)
  end

  def get_query_params
     if params[:basic_auth_username].present?
      @auth = {:username => params[:basic_auth_username], :password => params[:basic_auth_password]}
      options = request.post? ? { :query => params, :basic_auth => @auth } : {:basic_auth => @auth}
    else
      options = request.post? ? { :query => params} : {}
    end
    return options
  end

  def check_session_domain
    if params[:url].blank? && session[:domain].present?
      params[:url] = session[:domain]
    elsif params[:url].blank?
      render :template => "application/index"
      return
    end
  end

end

