import time
import sys
from scraper_service import analyze_product_logic, init_driver

# Redirect stdout to a file
sys.stdout = open("result.txt", "w", encoding="utf-8")

url = "https://www.trendyol.com/trendyol-man/t-shirt-p-76986428" 

print(f"Testing optimization with URL: {url}")
start_time = time.time()

# Mock driver for testing (or init one)
driver = init_driver()

try:
    # First run (Cold start / Cache Miss)
    print("\n--- RUN 1 (Cold) ---")
    result = analyze_product_logic(driver, url, 180, 80, 120, 90)
    print(f"Result 1 Title: {result.get('title', 'N/A')}")
    
    # Second run (Should be faster if we were using the cache wrapper, but here we test logic directly)
    # To test cache, we'd need to hit the API or use the wrapper. 
    # But here we just want to see if JSON extraction works.
    
    end_time = time.time()
    duration = end_time - start_time
    
    print("\n--- RESULT ---")
    print(f"Time taken: {duration:.2f} seconds")
    
    if "error" in result:
        print(f"Error: {result['error']}")

except Exception as e:
    print(f"Test failed with exception: {e}")
finally:
    if driver:
        driver.quit()
    sys.stdout.close()



