module ActiveAdmin
  module Views
    class CanvaCustomIndex < ActiveAdmin::Component

      def build(page_presenter, collection)
            script <<~SCRIPT.html_safe
                 function selectClick (e){
                  e.preventDefault();
                  const panel = e.target.parentNode
                   window.getSelection().selectAllChildren( panel.querySelector("table tbody"))
                 }

            SCRIPT
        collection.group_by(&:date).sort.each do |date, gigs|
          panel date, class: "canva_panel" do
            button "Select all", onClick: "selectClick(event); return false"
          table_for gigs do
            column "Venue" do | gig|
              gig.venue.name
            end
            column :name
            column :start_offset_time
          end
          end
        end
      end
      def self.index_name
        "Canva table"
      end

    end
  end
end
