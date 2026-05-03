* {
    bg: {{bg}};
    text: {{text}};
    lavender: {{lavender}};
    mauve: {{purple}};
    red: {{red}};
    surface0: {{surface}};

    font: "JetBrainsMono Nerd Font 11";
    background-color: @bg;
    border: 0px;
}

window {
    width: 700;
    orientation: horizontal;
    location: center;
    anchor: center;
    transparency: "screenshot";
    border: 2px;
    border-color: @lavender;
    border-radius: 8px;
    padding: 10px;
    spacing: 0;
    background-color: @bg;
    children: [ mainbox ];
}

mainbox {
    spacing: 0;
    margin: 5px;
    padding: 10px;
    background-color: @bg;
    children: [ inputbar, message, listview ];
}

inputbar {
    padding: 10px;
    margin: 5px 20px;
    border: 0px;
    border-radius: 0px;
    background-color: @bg;
    color: @text;
    spacing: 5px;
    children: [ prompt, entry ];
}

message {
    padding: 0;
    border: 0px;
    background-color: @bg;
}

entry, prompt, case-indicator {
    text-font: inherit;
    text-color: @text;
    background-color: @bg;
}

entry {
    cursor: pointer;
}

prompt {
    margin: 0px;
    color: @red;
}

listview {
    layout: vertical;
    padding: 10px;
    lines: 7;
    columns: 2;
    border: 0px;
    background-color: @bg;
    dynamic: false;
}

element {
    padding: 5px;
    vertical-align: 1;
    color: @text;
    font: inherit;
    background-color: @bg;
}

element-text {
    background-color: inherit;
    text-color: inherit;
    vertical-align: 0.5;
}

element selected.normal {
    background-color: @bg;
    border: 2px;
    border-color: @lavender;
    border-radius: 8px;
    color: @mauve;
}

element normal active {
    background-color: @bg;
    color: @text;
}

element-icon {
    background-color: inherit;
    size: 2.5em;
}

element normal urgent {
    background-color: @surface0;
}

element selected active {
    background-color: @bg;
    border: 2px;
    border-color: @lavender;
    color: @mauve;
}

button {
    padding: 6px;
    color: @lavender;
    horizontal-align: 0.5;
    border: 2px 0px 2px 2px;
    border-radius: 4px 0px 0px 4px;
    border-color: @lavender;
}

button selected normal {
    border: 2px 0px 2px 2px;
    border-color: @lavender;
}
