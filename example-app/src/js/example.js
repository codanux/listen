import { Listen } from 'listen';

window.testEcho = () => {
    const inputValue = document.getElementById("echoInput").value;

    //Listen.setLanguage({ language: 'tr-TR' });
    Listen.requestPermission().then((data) => {
        if (data.status === 'granted') {
            Listen.startListening();
        }
    });

    Listen.addListener('onWordReceived', (data) => {
        console.log('Received text:', data, data.text);
    });
}
