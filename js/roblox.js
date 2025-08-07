async function processGameBlock(gameBlock) {
    const placeId = gameBlock.getAttribute('id_places');
    let universeId = 0;
    let imageURL = "";
    let info_game = {};

    try {
        const universeResponse = await axios({
            url: `https://apis.roproxy.com/universes/v1/places/${placeId}/universe`,
            method: 'GET'
        });
        
        if (universeResponse.data.universeId) {
            universeId = universeResponse.data.universeId;
            
            const gameInfoResponse = await axios({
                url: `https://games.roproxy.com/v1/games?universeIds=${universeId}`,
                method: 'GET'
            });
            
            if (gameInfoResponse.data.data && gameInfoResponse.data.data[0]) {
                info_game = gameInfoResponse.data.data[0];
                
                const imageResponse = await axios({
                    url: `https://thumbnails.roproxy.com/v1/games/icons?universeIds=${universeId}&returnPolicy=PlaceHolder&size=256x256&format=Png&isCircular=false`,
                    method: 'GET'
                });
                
                if (imageResponse.data.data && imageResponse.data.data[0].imageUrl) {
                    imageURL = imageResponse.data.data[0].imageUrl;
                    
                    updateGameBlock(gameBlock, info_game, imageURL);
                }
            }
        }
    } catch (error) {
        console.error(`Error processing game block ${placeId}:`, error);
    }
}

function updateGameBlock(gameBlock, gameInfo, imageUrl) {

    const imageElement = gameBlock.querySelector('.place-image');
    if (imageElement) {
        imageElement.style.backgroundImage = `url('${imageUrl}')`;
    }
    

    const nameElement = gameBlock.querySelector('.place-name a');
    if (nameElement && gameInfo.name) {
        nameElement.textContent = gameInfo.name;
    }
    

    const creatorElement = gameBlock.querySelector('.place-creator');
    if (creatorElement && gameInfo.creator) {
        creatorElement.textContent = gameInfo.creator.name || "Unknown Creator";
    }
    

    const onlineCountElement = gameBlock.querySelector('.online-count span:last-child');
    if (onlineCountElement && gameInfo.playing) {
        onlineCountElement.textContent = gameInfo.playing;
    }
    

    const favoriteCountElement = gameBlock.querySelector('.favorite-count span');
    if (favoriteCountElement && gameInfo.favoritedCount) {
        favoriteCountElement.textContent = gameInfo.favoritedCount;
    }
}


document.addEventListener('DOMContentLoaded', () => {
    const gameBlocks = document.querySelector('[active="roblox"]').querySelectorAll('.info[id_places]');
    gameBlocks.forEach(block => {

        console.log(block)
        processGameBlock(block);
    });
});
