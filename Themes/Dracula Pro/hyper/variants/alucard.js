const background = "#F5F5F5";
const foreground = "#1F1F1F";
const selection = "#CFCFDE";
const comment = "#635D97";
const cyan = "#036A96";
const green = "#14710A";
const orange = "#A34D14";
const pink = "#A3144D";
const purple = "#644AC9";
const red = "#CB3A2A";
const yellow = "#846E15";
const lightRed = "#D74C3D";
const lightGreen = "#198D0C";
const lightYellow = "#9E841A";
const lightPurple = "#7862D0";
const lightPink = "#BF185A";
const lightCyan = "#047FB4";

exports.decorateConfig = (config) => {
  config = config || {};

  const colors = [
    foreground,
    red,
    green,
    yellow,
    purple,
    pink,
    cyan,
    orange,
    comment,
    lightRed,
    lightGreen,
    lightYellow,
    lightPurple,
    lightPink,
    lightCyan,
    selection,
  ];

  const customCSS = `
    .hyper_main {
        border: none !important;
    }
    .tabs_nav {
        background-color: ${background} !important;
    }
    .tabs_title {
        color: ${foreground} !important;
    }
    .tab_tab {
      color: ${comment} !important;
    }
    .tab_active {
        color: ${purple} !important;
    }
  `;

  return Object.assign({}, config, {
    backgroundColor: background,
    borderColor: selection,
    colors,
    css: `${config.css || ""} ${customCSS}`,
    cursorColor: comment,
    foregroundColor: foreground,
    minimal: false,
    selectionColor: selection,
    termCSS: `${config.termCSS || ""}`,
    vibrancy: "light",
  });
};
