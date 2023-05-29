require 'watir'
require 'webdrivers'
require 'csv'

class Scraper
    attr_accessor :browser, :csv, :scraped_apps_count

    def initialize
      Watir.default_timeout = 30
      @browser = Watir::Browser.new :chrome #, headless: true

      @csv = CSV.open("figma_plugins_#{Time.now.to_i}.csv", "a+")
      headers = %w[figma_url tagline installs_count]
      csv << headers

      @scraped_apps_count = 0
    end

    def call
      browser.goto 'https://www.figma.com/community/plugins'

      # Set a maximum number of iterations
      max_iterations = 100

      # Store the time when the loop starts
      start_time = Time.now

      # Set a maximum time limit
      max_seconds = 6000

      until max_iterations == 0
        sleep(3) # Wait for apps to load (can be reduced/increased depending on internet speed)
        visible_apps = browser.divs(class: 'feed_page--pluginRow--s7F1M').count
        puts "Number of visible apps: #{visible_apps}"
        if visible_apps == @scraped_apps_count
          puts "No new apps loaded"
          break
        end

        scrape_apps
        max_iterations -= 1

        if (Time.now - start_time) >= max_seconds
          puts "Time limit of #{max_seconds} seconds reached"
          break
        end
      end

    rescue StandardError => e
      puts "Error occurred: #{e.message}"
      puts e.backtrace
    ensure
      browser.quit
      puts "Scraped #{@scraped_apps_count} URLs"
      csv.close
    end

    def scrape_apps
      new_rows = browser.divs(class: 'feed_page--pluginRow--s7F1M')[scraped_apps_count..-1]
      new_rows.each do |row|
        row.divs[-3].hover
        app = [
          row.a.href, # figma_url
          row.divs(class: 'feed_page--pluginRowDescription--K7MHc').first&.text, # tagline
          row.divs[-3].following_sibling.text.split[2].to_i, # installs_count
        ]
        save_to_csv(app)
        @scraped_apps_count += 1
      end
    end

    def save_to_csv(app_listing_details)
      csv << app_listing_details
      csv.flush
    end

end

scraper = Scraper.new
scraper.call
