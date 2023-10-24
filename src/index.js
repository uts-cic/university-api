import SwaggerUI from "swagger-ui";
import jsYaml from "js-yaml";
import main from "../schema/main.yaml";

window.onload = function () {
  SwaggerUI({
    dom_id: "#main",
    spec: jsYaml.load(main),
  });
};
