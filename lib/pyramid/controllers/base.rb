require 'active_support/concern'
require 'pyramid/benchmark'
require 'pyramid/logging'

module Pyramid
  module Controller
    extend ActiveSupport::Concern
    include Pyramid::Benchmark
    include Pyramid::Logging

    # Computes a resource and returns a response for the request.
    #
    # Meant to be used in the context of a Sinatra route handler, like so:
    #
    #     get '/foo' do
    #       respond { {bar: :baz} }
    #     end
    #
    # Expects the provided block to return either a two-element array containing a custom status and the resource,
    # or just the resource itself (if the default status for the request method should be used). The block should also
    # set any custom request headers via the Sinatra +headers+ method.
    #
    # If no +representation_+ option is specified, +:json+ is assumed, and the provided resource is serialized to JSON.
    #
    # @param [Hash] options
    # @option options [Symbol] :representation (:json) the representation to be used for the computed response, as a
    #   Sinatra +mime_type+ value (eg :json, :html, :txt)
    # @return [Array] the response status and resource
    # @see #sresponse
    def respond(options = {}, &block)
      rv = benchmark("Compute resource", &block)
      (status, resource) = if rv.is_a?(Array)
        rv.slice(0, 2)
      else
        [nil, rv]
      end
      sresponse(resource, options.merge(status: status))
    end

    # Returns a Sinatra-friendly response enclosing the given resource (if any).
    #
    # Assumes that any custom request headers have previously been set via the Sinatra +headers+ method.
    #
    # If no +representation_+ option is specified, +:json+ is assumed, and the provided resource is serialized to JSON.
    #
    # @param [Object] resource
    # @param [Hash] options
    # @option options [Integer] :status the status code, if different than the one that would normally be chosen
    #   given the request method and resource
    # @option options [Symbol] :representation (:json) the representation to be used to serialize the resource, as a
    #   Sinatra +mime_type+ value (eg :json, :html, :txt)
    # @return [Array] the response status and resource
    def sresponse(resource, options = {})
      status = options[:status] || (if request.get? || request.head?
        resource.nil?? 404 : 200
      elsif request.put?
        201
      elsif request.delete?
        204
      else
        405
      end)
      if status != 204
        representation = options.fetch(:representation, :json)
        content_type(representation)
        resource = resource.to_json if resource && representation == :json
      end
      [status, resource]
    end

    # Halts the request and returns an error response.
    #
    # @param [Object] errors an object describing the error condition(s) that will be enclosed in an errors resource
    # @param [Hash] options
    # @see #sresponse
    # @see #errors_resource
    def halt(errors, options = {})
      super(sresponse(errors_resource(errors), options))
    end

    # Returns a resource providing a consistent structure for error information.
    #
    # @param [Object] errors an object describing the error condition(s)
    # @return [Hash]
    def errors_resource(errors)
      {errors: errors}
    end

    # Returns any grouped query ids that were provided in the named request parameter as a semicolon-delimited list
    # of integers.
    #
    # If any of the values in the list is not a positive integer, the request is halted with a 400 response.
    #
    # @param param_name the request parameter name
    # @return [Array]
    def grouped_query_ids(param_name)
      unless @grouped_query_ids
        @grouped_query_ids = params[param_name].split(';').each_with_object([]) do |v, m|
          begin
            m << Integer(v)
          rescue ArgumentError
            halt({param_name => "Bad query id value #{v}"}, status: 400)
          end
        end
      end
      @grouped_query_ids
    end

    # Returns the paged query options that were provided as the +page+ and +per+ request parameters.
    #
    # @return [Hash]
    def pagination_params
      page = params[:page].to_i
      page = 1 unless page > 0
      per = params[:per].to_i
      per = 25 unless per > 0
      {page: page, per: per}
    end

    # Returns the attribute filters that were provided as the +attr[]+ request parameters, or +nil+ if no such
    # parameters were provided.
    #
    # @return [Array]
    def attribute_filtering_params
      params[:attr] ? params[:attr].map(&:to_sym) : nil
    end

    # Returns the options relevant to paged queries that were provided as request parameters.
    #
    # @see #pagination_params
    # @see #attribute_filtering_params
    # @return [Hash]
    def paged_query_params
      pq = pagination_params
      af = attribute_filtering_params
      pq[:attr] = af if af
      pq
    end

    # Returns the options relevant to individual entity get requests that were provided as request parameters.
    #
    # @see #attribute_filtering_params
    # @return [Hash]
    def entity_get_params
      eg = {}
      af = attribute_filtering_params
      eg[:attr] = af if af
      eg
    end

    # Delegates the request to another controller, rewriting the request +PATH_INFO+ so that the subcontroller only
    # sees the splatted part.
    #
    # In the following example, a request for +/foo/:id/bar/baz+ would be handled by +BarController.baz+.
    #
    #     map('/foo') { run FooController }
    #
    #     class FooController
    #       get '/:id/bar/*' do
    #         delegate_to_subcontroller BarController, prefix: "/#{params[:id]}"
    #       end
    #     end
    #
    #     class BarController
    #       get '/:id/baz' do
    #         "baz! #params[:id]"
    #       end
    #     end
    #
    # @param [Class] subcontroller_class
    # @param [Hash] options
    # @option options [String] :prefix ('/') a string to prepend to the splatted path
    def delegate_to_subcontroller(subcontroller_class, options = {})
      prefix = options.fetch(:prefix, '/')
      splat = params[:splat].first ? "/#{params[:splat].first}" : ''
      path_info = "#{prefix}#{splat}"
      subcontroller_class.call(env.merge('PATH_INFO' => path_info))
    end

    included do
      set :show_exceptions, false

      not_found do
        halt('Route not found', status: 404)
      end

      error do
        msg = env['sinatra.error'] ? env['sinatra.error'].message : 'Unknown error'
        halt(msg, status: 500)
      end
    end
  end
end
