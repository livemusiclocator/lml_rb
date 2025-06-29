class Web::ExplorerController < Web::ApplicationController

  def index
    render
  end

  def show
    @gig = Lml::Gig.find(params[:id])
    render
  end
end
