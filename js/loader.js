class RequestTracker {
  constructor() {

    this.lastRequestTime = null;
    this.timeoutId = null;
    this.delay = 2000;
    this.setupPerformanceObserver();
    this.setupStyleTracker();
  }

  setupPerformanceObserver() {
    const observer = new PerformanceObserver((list) => {

      list.getEntries().forEach((entry) => {

        const type = this.detectResourceType(entry);

        this.logRequest(type, entry.name);
        this.resetTimer();
      });
    });
    observer.observe({ type: 'resource', buffered: true });
  }

  setupStyleTracker() {
    const observer = new MutationObserver((mutations) => {

      mutations.forEach((mutation) => {

        if (mutation.type === 'attributes' && mutation.attributeName === 'style') {
          const bgImage = mutation.target.style.backgroundImage;

          if (bgImage?.includes('url(')) {

            const url = bgImage.match(/url\(["']?(.*?)["']?\)/)[1];
            this.logRequest('img', url);
            this.resetTimer();

          }
        }
      });
    });

    observer.observe(document.documentElement, {
      attributes: true,
      attributeFilter: ['style'],
      subtree: true,
    });
  }

  detectResourceType(entry) {
    const url = entry.name.toLowerCase();
    
    if (url.match(/\.(png|jpg|jpeg|gif|webp|svg|avif|bmp)/)) {
      return 'img';
    }
    
    if (entry.initiatorType === 'css') {
      return 'img';
    }
    
    return entry.initiatorType || 'other';
  }

  logRequest(type, url) {

    const loaderDiv = document.getElementById("loader-footer")
    loaderDiv.innerText = `Type: ${type} | URL: ${url}`
  }

  resetTimer() {

    if (this.timeoutId) clearTimeout(this.timeoutId);
    this.timeoutId = setTimeout(() => {
        
      const loaderDiv = document.getElementById("loader-footer")
      loaderDiv.innerText = "Successfully"
      document.querySelector('.fullscreen-loader').style.transform = 'translateY(-1000px)';

    }, this.delay);
}
}

const tracker = new RequestTracker();
