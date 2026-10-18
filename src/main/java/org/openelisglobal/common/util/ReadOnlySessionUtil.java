package org.openelisglobal.common.util;

import javax.persistence.EntityManager;

import org.hibernate.FlushMode;
import org.hibernate.Session;
import org.springframework.transaction.interceptor.TransactionAspectSupport;

/**
 * Helpers for methods that load many entities in a single
 * {@code @Transactional(readOnly = true)} transaction.
 */
public final class ReadOnlySessionUtil {

    private ReadOnlySessionUtil() {
    }

    /**
     * Makes the current Hibernate session read only with manual flush. readOnly
     * alone does not reach Hibernate with the JPA setup of this project, so
     * without this every query dirty-checks all the entities already loaded in
     * the session, which gets slower as the session grows.
     *
     * Only applied when the calling {@code @Transactional} method started the
     * transaction: a caller's write transaction is left untouched.
     */
    public static void disableDirtyChecking(EntityManager entityManager) {
        if (TransactionAspectSupport.currentTransactionStatus().isNewTransaction()) {
            Session session = entityManager.unwrap(Session.class);
            session.setHibernateFlushMode(FlushMode.MANUAL);
            session.setDefaultReadOnly(true);
        }
    }
}
