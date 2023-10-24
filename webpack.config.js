const path = require("path");
const HtmlWebpackPlugin = require("html-webpack-plugin");
const CopyWebpackPlugin = require("copy-webpack-plugin");

module.exports = {
  mode: "development",
  entry: "./src/index.js",
  output: {
    filename: "bundle.js",
    path: path.resolve(__dirname, "dist"),
  },
  devServer: {
    static: "./dist",
    open: true,
  },
  module: {
    rules: [
      {
        test: /\.yaml$/,
        use: "raw-loader",
      },
    ],
  },
  performance: {
    hints: "warning",
    maxAssetSize: 10485760,
    maxEntrypointSize: 10485760,
  },
  plugins: [
    new HtmlWebpackPlugin({
      template: "./src/index.html",
    }),
    new CopyWebpackPlugin({
      patterns: [
        {
          from: "node_modules/swagger-ui/dist/swagger-ui.css",
          to: "swagger-ui.css",
        },
      ],
    }),
  ],
};
