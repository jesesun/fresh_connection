module FreshConnection
  class AccessControl
    class << self
      def force_master_access(&block)
        switch_to(:master, &block)
      end

      def access(enable_replica_access, &block)
        if access_db
          block.call
        else
          db = enable_replica_access ? :replica : :master
          switch_to(db, &block)
        end
      end

      def replica_access?
        access_db == :replica
      end

      def catch_exceptions
        return @catch_exceptions if defined?(@catch_exceptions)
        @catch_exceptions = [ActiveRecord::StatementInvalid]
        @catch_exceptions << ::Mysql2::Error if defined?(::Mysql2)

        if defined?(::PG)
          @catch_exceptions << ::PG::Error
          @catch_exceptions << ::PGError if defined?(::PGError)
        end

        @catch_exceptions
      end

      private

      def switch_to(new_db)
        old_db = access_db
        access_to(new_db)
        yield
      ensure
        access_to(old_db)
      end

      def access_db
        Thread.current[:fresh_connection_access_target]
      end

      def access_to(db)
        Thread.current[:fresh_connection_access_target] = db
      end
    end
  end
end
