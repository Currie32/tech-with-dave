# Create a Multilingual Chatbot using OpenAI APIs and Dash

This article provides an overview of how you can use OpenAI’s <a href=https://platform.openai.com/docs/guides/gpt/chat-completions-api target="blank">chat completions API</a> and <a href=https://platform.openai.com/docs/guides/speech-to-text/transcriptions target="blank">Whisper-1 API</a> to develop a multilingual chatbot. Several links will be provided to <a href=https://github.com/Currie32/practice-a-language/tree/master target="blank">my GitHub repo</a> that stores that code for <a href=https://practicealanguage.xyz target="blank">https://practicealanguage.xyz</a>. Many tech stacks could be used to build this web app, but I selected Dash as the framework to keep the codebase small and make the UI interactive. This can be accomplished as Dash uses <a href=https://dash.plotly.com/basic-callbacks target="blank">callbacks</a> for simplified frontend-backend interactions and although Dash is built using React.js, the code can largely be written in Python.

## Prompting GPT-3.5-Turbo

To set up the conversation, dropdown menus are provided to specify the <a href=https://github.com/Currie32/practice-a-language/blob/v1.1.1/pages/home.py#L53-L58 target="blank">language that you speak</a>, the <a href=https://github.com/Currie32/practice-a-language/blob/v1.1.1/pages/home.py#L65-L70 target="blank">language that you want to learn</a>, and the <a href=https://github.com/Currie32/practice-a-language/blob/v1.1.1/pages/home.py#L83-L106 target="blank">conversation setting</a>. This information is <a href =https://github.com/Currie32/practice-a-language/blob/v1.1.1/assets/chat_request.py#L123-L127 target="blank">used to prompt</a> GPT-3.5-Turbo (GPT). GPT-4 could also be used, but given its higher costs, and the quality of responses from GPT-3.5, I found that it was a suitable tradeoff to stick with GPT-3.5.

Writing a prompt that would reliably produce a suitable response from GPT took a few iterations as it could reply in the language that you want to learn as well as in the language that you speak. For example:

```
Bonjour, qu'est-ce que je peux vous servir aujourd'hui? (Hello, what can I serve you today?)
```

Fortunately, after adding an <a href=https://github.com/Currie32/practice-a-language/blob/v1.1.1/assets/chat_request.py#L127 target="blank">example response</a> (<a href=https://lilianweng.github.io/posts/2023-03-15-prompt-engineering/#few-shot target="blank">one-shot learning</a>), GPT hasn’t made this mistake again and offers varied statements to start the conversation. I’ve also increased the temperature to 1.5 (from the default of 1) to provide <a href=https://community.openai.com/t/cheat-sheet-mastering-temperature-and-top-p-in-chatgpt-api-a-few-tips-and-tricks-on-controlling-the-creativity-deterministic-output-of-prompt-responses/172683 target="blank">more diverse responses</a> from GPT.

## User response

The user can respond using either text or audio. Providing a text response is <a href=https://github.com/Currie32/practice-a-language/blob/v1.1.1/pages/home.py#L335 target="blank">pretty straightforward</a> as the user can reply in the language that they want to learn, or <a href=https://github.com/Currie32/practice-a-language/blob/v1.1.1/pages/home.py#L370 target="blank">in the language they know</a> and it will be translated using GoogleTranslator (via the Python package <a href=https://deep-translator.readthedocs.io/en/latest/usage.html#google-translate target="blank">deep-translator</a>). Although this translation isn’t always perfect, it’s free, which makes it a great tool for keeping costs down.

If the user responds using an <a href=https://github.com/Currie32/practice-a-language/blob/v1.1.1/pages/home.py#L520-L545 target="blank">audio recording</a> it’s a bit more complicated. A <a href=https://dash.plotly.com/clientside-callbacks target="blank">clientside_callback</a> is required to access the microphone on the user’s device to create the audio recording. This is because when the app is deployed on to Google Cloud Run, a normal callback function, which operates on the server-side (backend), doesn't have access to a device's microphone. Using a clientside_callback can access a device's microphone as this code operates on the front-end of the app.

When the user makes a recording, it is sent to the server-side of the app using a <a href=https://github.com/Currie32/practice-a-language/blob/v1.1.1/pages/home.py#L559-L565 target="blank">POST request</a>. The recording is then <a href=https://github.com/Currie32/practice-a-language/blob/v1.1.1/app.py#L97-L99 target="blank">saved locally</a> before being <a href=https://github.com/Currie32/practice-a-language/blob/v1.1.1/assets/chat_request.py#L40-L42 target="blank">sent to OpenAI’s Whisper model</a> for speech-to-text transformation. The transcript from the Whisper model populates the user response input field, which allows the user to verify that they have been understood correctly before submitting their response to GPT and continuing the conversation.

## Continuing the conversation and keeping the costs down

Each message from GPT and the user is appended to a list. As the conversation grows, only the <a href=https://github.com/Currie32/practice-a-language/blob/v1.1.1/pages/home.py#L383 target="blank">most recent portion</a> of the list will be sent to GPT as the cost of the API call grows with each token. As this is a simple language-learning app, it’s not essential for GPT to be aware of the full conversation, so we can take this cost-saving measure.

## Understanding GPT’s responses

Depending on your knowledge of the language that you want to learn, you might not fully understand what GPT has said in its response. The <a href=https://github.com/BvdLind/dash-selectable target="blank">dash_selectable</a> package allows you to know what text has been highlighted and this can be <a href=https://github.com/Currie32/practice-a-language/blob/v1.1.1/callbacks/translate.py#L31-L36 target="blank">fed to GoogleTranslate</a> to provide you with a translation (another good use case for free translation).

## Conclusion

I hope that you’ve enjoyed this overview of developing a chatbot to help you practice a language. Feel free to clone the repo on <a href=https://github.com/Currie32/practice-a-language/tree/master target="blank">my GitHub</a> and run the app yourself, and if you would like to deploy your own chatbot to Google Cloud Run, take a look at [this article](./deploy-a-dash-app-on-google-cloud-run.md) to read how to do that. I'll be keeping <a href=https://practicealanguage.xyz target="blank">https://practicealanguage.xyz</a> free and open-source, so it'll be waiting for you whenever you want to take another look at it.
