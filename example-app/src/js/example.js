import { Listen } from 'listen';

window.testEcho = () => {
    const inputValue = document.getElementById("echoInput").value;
    Listen.echo({ value: inputValue })
}
