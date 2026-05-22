window.POS_CONFIG = {
  business: {
    name: "Arctic Market",
    accentName: "POS",
    tagline: "Retail Management System"
  },

  branding: {
    accent: "#ff3c5f",
    yellow: "#ffe135",
    cyan: "#00e5ff",
    green: "#39ff14"
  },

  taxes: [
    {
      id: "gst",
      label: "GST",
      rate: 0.05,
      enabled: false
    },
    {
      id: "pst",
      label: "PST",
      rate: 0.07,
      enabled: false
    }
  ],

  loyalty: {
    enabled: true,
    pointsPerDollar: 1
  },

  currency: "$",

  features: {
    loyalty: true,
    promos: true,
    taxToggleUI: true
  }
};
