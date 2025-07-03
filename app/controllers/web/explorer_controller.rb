class Web::ExplorerController < Web::ApplicationController
  layout 'web/layouts/explorer'
  def index
     search = Web::GigSearch.new(search_params)
     if search.valid?
       set_meta_tags search
     else
       set_meta_tags Web::GigSearch.new
     end
    render
  end

  def show
    @gig = Lml::Gig.find(params[:id])
    render
  end

  def search_params
    # hack until we change the query string params to be genre=[]
    tags = params[:tags]
    params.delete :tags
    params[:genres] = tags
    params.transform_keys(&:underscore).permit(:location,:date_range,:custom_date,:genres=>[])
  end
end
