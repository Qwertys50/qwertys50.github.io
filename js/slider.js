        document.addEventListener('DOMContentLoaded', function() {
            const slides = document.querySelectorAll('.info');
            const prevBtn = document.getElementById('prevBtn');
            const nextBtn = document.getElementById('nextBtn');
            let currentSlide = 0;
            
            showSlide(currentSlide);
            
            // Обработчики кнопок
            nextBtn.addEventListener('click', function() {
                currentSlide++;
                if (currentSlide >= slides.length) {
                    currentSlide = 0;
                }
                showSlide(currentSlide);
            });
            
            prevBtn.addEventListener('click', function() {
                currentSlide--;
                if (currentSlide < 0) {
                    currentSlide = slides.length - 1;
                }
                showSlide(currentSlide);
            });
            
            // Функция для показа слайда
            function showSlide(index) {
                slides.forEach((slide, i) => {
                    slide.style.transform = `translateX(${100 * (i - index)}%)`;
                    slide.classList.toggle('active', i === index);
                });
            }
        });