// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("controllers", application)
import SidebarController from "controllers/sidebar_controller"
import DropdownController from "controllers/dropdown_controller"

application.register("sidebar", SidebarController)
application.register("dropdown", DropdownController)
