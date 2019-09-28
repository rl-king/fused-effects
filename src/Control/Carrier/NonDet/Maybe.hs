{-# LANGUAGE DeriveFunctor #-}
module Control.Carrier.NonDet.Maybe
( -- * NonDet effects
  module Control.Effect.NonDet
  -- * NonDet carrier
, runNonDet
, NonDetC(..)
  -- * Re-exports
, Carrier
, Has
, run
) where

import Control.Applicative (liftA2)
import Control.Carrier
import Control.Effect.NonDet
import Control.Monad (MonadPlus (..))
import qualified Control.Monad.Fail as Fail
import Control.Monad.Fix
import Control.Monad.IO.Class
import Control.Monad.Trans.Class

runNonDet :: NonDetC m a -> m (Maybe a)
runNonDet = runNonDetC

newtype NonDetC m a = NonDetC { runNonDetC :: m (Maybe a) }
  deriving (Functor)

instance Applicative m => Applicative (NonDetC m) where
  pure = NonDetC . pure . Just
  {-# INLINE pure #-}
  NonDetC f <*> NonDetC a = NonDetC (liftA2 (<*>) f a)
  {-# INLINE (<*>) #-}

-- $
--   prop> run (runNonDet empty) === Nothing
instance Applicative m => Alternative (NonDetC m) where
  empty = NonDetC (pure Nothing)
  {-# INLINE empty #-}
  NonDetC a <|> NonDetC b = NonDetC (liftA2 (<|>) a b)
  {-# INLINE (<|>) #-}

instance Monad m => Monad (NonDetC m) where
  NonDetC a >>= f = NonDetC (a >>= maybe (pure Nothing) (runNonDet . f))
  {-# INLINE (>>=) #-}

instance Fail.MonadFail m => Fail.MonadFail (NonDetC m) where
  fail = lift . Fail.fail
  {-# INLINE fail #-}

instance MonadFix m => MonadFix (NonDetC m) where
  mfix f = NonDetC (mfix (runNonDet . maybe (error "mfix (NonDetC): function returned failure") f))
  {-# INLINE mfix #-}

instance MonadIO m => MonadIO (NonDetC m) where
  liftIO = lift . liftIO
  {-# INLINE liftIO #-}

instance (Alternative m, Monad m) => MonadPlus (NonDetC m)

instance MonadTrans NonDetC where
  lift = NonDetC . fmap Just
  {-# INLINE lift #-}
