require 'watir'
require 'webdrivers'
require 'csv'

TRYYYYYYY: https://stackoverflow.com/questions/73979692/ruby-until-loop-ending-too-soon

class Scraper
    attr_accessor :browser
  
    def initialize
      Watir.default_timeout = 30
      @browser = Watir::Browser.new :chrome #, headless: true
    end
  
    def call
        browser.goto 'https://www.figma.com/community/plugins'
    
        # Random values below to make sure new apps array is bigger
        old_app_urls = ['url1']
        new_app_urls = ['url1', 'url2']

        old_app_as = []
        new_app_as = []

        # Set a maximum number of iterations
        max_iterations = 100

        # Store the time when the loop starts
        start_time = Time.now

        # Set a maximum time limit
        max_seconds = 6000
        timeout = false # Initialize timeout variable to false
    
        until old_app_urls.count == new_app_urls.count || timeout  || max_iterations == 0
            old_app_as = new_app_as
            old_app_urls = old_app_as.map { |row| row.a.href }
            browser.scroll.to [0, 99999999999]
            sleep(3)
        
            # Grab only new app URLs that have been added to the page since last loop
            new_app_as = browser.divs(class: 'feed_page--pluginRow--s7F1M').to_a - old_app_as
            new_app_urls += new_app_as.map { |row| row.a.href }
        
            browser.scroll.to [0, 99999999999]
            sleep(3)
            puts "Number of visible apps: #{new_app_urls.count}"
        
            max_iterations -= 1
            timeout = Time.now - start_time >= max_seconds # Check if the timeout has been reached
          end
    
        scrape_apps
        
      rescue StandardError => e
        puts "Error occurred: #{e.message}"
        puts e.backtrace
      ensure
        browser.quit
      end
    
      def scrape_apps
        apps = []
        rows = browser.divs(class: 'feed_page--pluginRow--s7F1M')
        rows.each do |row|
          row.divs[-3].hover
          app = {
            figma_url: row.a.href,
            tagline: row.text.split("\n")[-4],
            installs_count: row.divs[-3].following_sibling.text.split[2].to_i
          }
          apps << app
        end
        puts "Scraped #{apps.count} URLs"
        save_to_csv(apps)
      end

    def save_to_csv(app_listing_details)
        CSV.open("figma_plugins_#{Time.now.to_i}.csv", "a+") do |csv|
          csv << app_listing_details[0].keys
          app_listing_details.each do |row|
            csv << row.values
          end
        end
    end

end

scraper = Scraper.new
scraper.call