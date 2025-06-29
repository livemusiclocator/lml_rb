class Web::ExplorerController < Web::ApplicationController
  layout 'web/layouts/explorer'
  def index
    render
  end

  def show
    @gig = Lml::Gig.find(params[:id])
    render
  end
end
