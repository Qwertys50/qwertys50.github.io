const text = "My Project";
const container = document.querySelector('.container');

const characters = text.replace(/\s/g, '').split('');

characters.forEach(char => {
  const box = document.createElement('div');
  box.className = 'box notranslate';
  box.textContent = char;
  container.appendChild(box);
});


var observer = new MutationObserver((mutations)=>{
var classMutation = mutations.find(m => m.attributeName === 'class');
var langMutation =  mutations.find(m => m.attributeName === 'lang');

if ((classMutation?.target.classList.contains('translated-ltr') ||
    classMutation?.target.classList.contains('translated-rtl')) && langMutation) {
    console.log('translated to', langMutation.target.lang);
    }
});

observer.observe(document.documentElement, { attributes: true });

const boxes = container.querySelectorAll(".box");

boxes.forEach(element => {
    element.addEventListener("mouseover", (event) => {

        document.querySelectorAll(".box").forEach(box => {
            box.classList.remove(
                "hovered", "prev1", "prev2", "next1", "next2"
            );
        });
        
        event.target.classList.add("hovered");

        const prevSibling = event.target.previousElementSibling;
        const prevPrevSibling = prevSibling?.previousElementSibling;
        const nextSibling = event.target.nextElementSibling;
        const nextNextSibling = nextSibling?.nextElementSibling;

        if (prevPrevSibling) {
            prevPrevSibling.classList.add("prev2");
        }
        if (prevSibling) {
            prevSibling.classList.add("prev1");
        }
        if (nextNextSibling) {
            nextNextSibling.classList.add("next2");
        }
        if (nextSibling) {
            nextSibling.classList.add("next1");
        }
    });

    element.addEventListener("mouseout", () => {
        document.querySelectorAll(".box").forEach(box => {
            box.classList.remove(
                "hovered", "prev1", "prev2", "next1", "next2"
            );
        });
    });
});