package utils

import species.groups.UserGroup;
import grails.plugins.springsecurity.Secured;

class NewsletterController {

	static allowedMethods = [save: "POST", update: "POST", delete: "POST"]
	def userGroupService
	
	def index = {
		redirect url: createLink(mapping:'userGroupGeneric', action: "pages", params: params)
	}

	def list = {
		params.max = Math.min(params.max ? params.int('max') : 10, 100)
		redirect url: createLink(mapping:'userGroupGeneric', action: "pages", params: params)
	}

	@Secured(['ROLE_USER'])
	def create = {
		def newsletterInstance = new Newsletter()
		newsletterInstance.properties = params
		return [newsletterInstance: newsletterInstance]
	}

	@Secured(['ROLE_USER'])
	def save = {
		log.debug params
		def newsletterInstance = new Newsletter(params)
		if(params.userGroup) {
			def userGroupInstance = userGroupService.get(params.userGroup);
			userGroupInstance.addToNewsletters(newsletterInstance);
			if (userGroupInstance.save(flush: true)) {
				flash.message = "${message(code: 'default.created.message', args: [message(code: 'newsletter.label', default: 'Newsletter'), newsletterInstance.id])}"
				redirect url: createLink(mapping:'userGroupPageShow', params:['webaddress':newsletterInstance.userGroup.webaddress, 'newsletterId':newsletterInstance.id])
			}
			else {
				render(view: "create", model: [userGroupInstance:userGroupInstance, newsletterInstance: newsletterInstance])
			}
		} else {
			if (newsletterInstance.save(flush: true)) {
				flash.message = "${message(code: 'default.created.message', args: [message(code: 'newsletter.label', default: 'Newsletter'), newsletterInstance.id])}"
				redirect(controller:"userGroup", action: "page", params:['newsletterId':newsletterInstance.id])
			}

			else {
				render(view: "create", model: [newsletterInstance: newsletterInstance])
			}
		}
	}

	def show = {
		def newsletterInstance = Newsletter.get(params.id)
		if (!newsletterInstance) {
			flash.message = "${message(code: 'default.not.found.message', args: [message(code: 'newsletter.label', default: 'Newsletter'), params.id])}"
			redirect  url: createLink(mapping:'userGroupGeneric', action: "pages")
		}
		else {
			if(newsletterInstance.userGroup) {
				[userGroupInstance:newsletterInstance.userGroup, newsletterInstance: newsletterInstance]	
			}
			else {
				[newsletterInstance: newsletterInstance]
			}
		}
	}

	@Secured(['ROLE_USER'])
	def edit = {
		def newsletterInstance = Newsletter.get(params.id)
		if (!newsletterInstance) {
			flash.message = "${message(code: 'default.not.found.message', args: [message(code: 'newsletter.label', default: 'Newsletter'), params.id])}"
			redirect  url: createLink(mapping:'userGroupGeneric', action: "pages")
		}
		else {
			return [newsletterInstance: newsletterInstance]
		}
	}

	@Secured(['ROLE_USER'])
	def update = {
		def newsletterInstance = Newsletter.get(params.id)

		if (newsletterInstance) {
			if (params.version) {
				def version = params.version.toLong()
				if (newsletterInstance.version > version) {

					newsletterInstance.errors.rejectValue("version", "default.optimistic.locking.failure", [
						message(code: 'newsletter.label', default: 'Newsletter')]
					as Object[], "Another user has updated this Newsletter while you were editing")
					render(view: "edit", model: [newsletterInstance: newsletterInstance])
					return
				}
			}
			newsletterInstance.properties = params
			if(params.userGroup) {
				def userGroupInstance = userGroupService.get(params.userGroup);
				userGroupInstance.addToNewsletters(newsletterInstance);
				if (userGroupInstance.save(flush: true)) {
					flash.message = "${message(code: 'default.updated.message', args: [message(code: 'newsletter.label', default: 'Newsletter'), newsletterInstance.id])}"
					redirect url: createLink(mapping:'userGroupPageShow', params:['webaddress':newsletterInstance.userGroup.webaddress, 'newsletterId':newsletterInstance.id, userGroupInstance:userGroupInstance])
				}
				else {
					render(view: "edit", model: [userGroupInstance:userGroupInstance, newsletterInstance: newsletterInstance])
				}
			} else {
				if (!newsletterInstance.hasErrors() && newsletterInstance.save(flush: true)) {
					flash.message = "${message(code: 'default.updated.message', args: [message(code: 'newsletter.label', default: 'Newsletter'), newsletterInstance.id])}"

					redirect  url: createLink(mapping:'userGroupGeneric', action: "page", id: newsletterInstance.id)
				}
				else {
					render(view: "edit", model: [newsletterInstance: newsletterInstance])
				}
			}
		}
		else {
			flash.message = "${message(code: 'default.not.found.message', args: [message(code: 'newsletter.label', default: 'Newsletter'), params.id])}"
			redirect  url: createLink(mapping:'userGroupGeneric', action: "pages")
		}
	}

	@Secured(['ROLE_USER'])
	def delete = {
		def newsletterInstance = Newsletter.get(params.id)
		if (newsletterInstance) {
			try {
				newsletterInstance.delete(flush: true)
				flash.message = "${message(code: 'default.deleted.message', args: [message(code: 'newsletter.label', default: 'Newsletter'), params.id])}"
				if(newsletterInstance.userGroup) {
					redirect  url: createLink(mapping:'userGroup', action: "pages", params:['webaddress':newsletterInstance.userGroup.webaddress])
					return;
				}
				redirect  url: createLink(mapping:'userGroupGeneric', action: "pages")
			}
			catch (org.springframework.dao.DataIntegrityViolationException e) {
				flash.message = "${message(code: 'default.not.deleted.message', args: [message(code: 'newsletter.label', default: 'Newsletter'), params.id])}"
				if(params.userGroup) {
					redirect url: createLink(mapping:'userGroupPageShow', params:['webaddress':params.userGroup, 'newsletterId':params.id])
					return;
				}
				redirect  url: createLink(mapping:'userGroupGeneric', action: "page", id: params.id)
			}
		}
		else {
			flash.message = "${message(code: 'default.not.found.message', args: [message(code: 'newsletter.label', default: 'Newsletter'), params.id])}"
			if(params.userGroup) {
				redirect url: createLink(mapping:'userGroupPageShow', params:['webaddress':params.userGroup, 'newsletterId':params.id])
				return;
			}
			redirect  url: createLink(mapping:'userGroupGeneric', action: "pages")
		}
	}
}
