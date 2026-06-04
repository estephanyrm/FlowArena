require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 900] do |driver_options|
    driver_options.add_argument("--headless=new")
    driver_options.add_argument("--no-sandbox")
    driver_options.add_argument("--disable-dev-shm-usage")
    driver_options.add_argument("--disable-gpu")
    driver_options.add_argument("--disable-software-rasterizer")
    driver_options.add_argument("--remote-debugging-port=9222")
    driver_options.add_argument("--window-size=1400,900")
  end
end