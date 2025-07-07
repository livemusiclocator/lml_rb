class Web::PagesController < Web::ApplicationController
  include HighVoltage::StaticPage

  layout "web/layouts/about"

end
