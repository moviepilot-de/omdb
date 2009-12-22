class Admin::SearchController < ApplicationController
  before_filter :admin_required, :get_worker
  before_filter :get_status, :only => [ :index, :status ]
  verify :method => :post, :only => :rebuild_index

  def index
  end

  def status
    render :partial => 'status'
  end

  def rebuild_index
    @worker.rebuild_index  
    redirect_to :action => 'index'
  end

  protected

  def get_worker
    @worker = MiddleMan.get_worker 'ferret_server'
  end

  def get_status
    @status = @worker.status
  end
end
