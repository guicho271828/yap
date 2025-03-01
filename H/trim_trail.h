




















#ifdef FROZEN_STACKS
{
  tr_fr_ptr pt0, pt1, pbase, ptop;
  pbase = B->cp_tr, ptop = TR;
  pt0 = pt1 = TR - 1;
  while (pt1 >= pbase) {
    BEGD(d1);
    d1 = TrailTerm(pt1);
    if (IsVarTerm(d1)) {
      if (d1 < (CELL)HBREG || d1 > Unsigned(B->cp_b)) {
        TrailTerm(pt0) = d1;
        TrailVal(pt0) = TrailVal(pt1);
        pt0--;
      }
      pt1--;
    } else if (IsPairTerm(d1)) {
      CELL *pt = RepPair(d1);
#ifdef LIMIT_TABLING
      if ((ADDR)pt == LOCAL_TrailBase) {
        sg_fr_ptr sg_fr = (sg_fr_ptr)TrailVal(pt1);
        SgFr_state(sg_fr)--; /* complete_in_use --> complete : compiled_in_use
                                --> compiled */
        insert_into_global_sg_fr_list(sg_fr);
      } else
#endif /* LIMIT_TABLING */
          if (IN_BETWEEN(LOCAL_TrailBase, pt, LOCAL_TrailTop)) {
        /* skip, this is a problem because we lose information,
           namely active references */
        pt1 = (tr_fr_ptr)pt;
      } else if (IN_BETWEEN(H0, pt, HR) && IsApplTerm(HeadOfTerm(d1))) {
	    RESET_VARIABLE(&TrailTerm(pt1));
	    	    RESET_VARIABLE(&TrailVal(pt1));
	    Term t = HeadOfTerm(d1);
        Functor f = FunctorOfTerm(t);
        if (f == FunctorBlob) {
          Int tag = Yap_blob_tag(t);
          GLOBAL_OpaqueHandlers[tag].cut_handler(d1);

          } else {
          pt0--;
        }
        pt1--;
        continue;
      } else if ((*pt & (LogUpdMask | IndexMask)) == (LogUpdMask | IndexMask)) {
        LogUpdIndex *cl = ClauseFlagsToLogUpdIndex(pt);
        int erase;
#if defined(THREADS) || defined(YAPOR)
        PredEntry *ap = cl->ClPred;
#endif

        LOCK(ap->PELock);
        DEC_CLREF_COUNT(cl);
        cl->ClFlags &= ~InUseMask;
        erase = (cl->ClFlags & (ErasedMask | DirtyMask)) && !(cl->ClRefCount);
        if (erase) {
          /* at this point, we are the only ones accessing the clause,
             hence we don't need to have a lock it */
          if (cl->ClFlags & ErasedMask)
            Yap_ErLogUpdIndex(cl);
          else
            Yap_CleanUpIndex(cl);
        }
        UNLOCK(ap->PELock);
	RESET_VARIABLE(&TrailTerm(pt0));
	RESET_VARIABLE(&TrailVal(pt0));
	pt0--;
      } else {
        TrailTerm(pt0) = d1;
        TrailVal(pt0) = TrailVal(pt1);
        pt0--;
      }
      pt1--;
    } else if (IsApplTerm(d1)) {
      if (IN_BETWEEN(HBREG, RepAppl(d1), B->cp_b)) {
        /* deterministic binding to multi-assignment variable */
	RESET_VARIABLE(&TrailTerm(pt0));
	RESET_VARIABLE(&TrailVal(pt0));
	pt0--;
	RESET_VARIABLE(&TrailVal(pt0));
   	RESET_VARIABLE(&TrailTerm(pt0));
	pt0--;
	pt1 -= 2;
      } else {
        TrailVal(pt0) = TrailVal(pt1);
        TrailTerm(pt0) = d1;
        TrailVal(pt0 - 1) = TrailVal(pt1 - 1);
        TrailTerm(pt0 - 1) = TrailTerm(pt1 - 1);
        pt0 -= 2;
        pt1 -= 2;
      }
    } else {
      TrailTerm(pt0) = d1;
      TrailVal(pt0) = TrailVal(pt1);
      pt0--;
      pt1--;
    }
    ENDD(d1);
  }
  if (pt0 != pt1) {
    int size;
    pt0++;
    size = ptop - pt0;
    memmove(pbase, pt0, size * sizeof(struct trail_frame));
    if (ptop != TR) {
      memmove(pbase + size, ptop, (TR - ptop) * sizeof(struct trail_frame));
      size += (TR - ptop);
    }
    TR = pbase + size;
  }
}
#else
{
  tr_fr_ptr pt1, pt0;
  pt1 = pt0 = B->cp_tr;
  while (pt1 != TR) {
    BEGD(d1);
    d1 = TrailTerm(pt1);
    if (IsVarTerm(d1)) {
      if (d1 < (CELL)HBREG || d1 > Unsigned(B->cp_b)) {
#ifdef FROZEN_STACKS
        TrailVal(pt0) = TrailVal(pt1);
#endif /* FROZEN_STACKS */
        TrailTerm(pt0) = d1;
        pt0++;
      } else {
	RESET_VARIABLE(&TrailTerm(pt0));
	RESET_VARIABLE(&TrailVal(pt0));
	pt0++;
      }
      pt1++;
    } else if (IsApplTerm(d1)) {
      if (IN_BETWEEN(HBREG, RepAppl(d1), B->cp_b)) {
#ifdef FROZEN_STACKS
	RESET_VARIABLE(&TrailTerm(pt0));
	RESET_VARIABLE(&TrailVal(pt0));
	pt0++;
	RESET_VARIABLE(&TrailTerm(pt0));
	RESET_VARIABLE(&TrailVal(pt0));
	pt0++;
        pt1 += 2;
#else
	RESET_VARIABLE(&TrailTerm(pt0));
	RESET_VARIABLE(&TrailVal(pt0));
	pt0++;
	RESET_VARIABLE(&TrailTerm(pt0));
	RESET_VARIABLE(&TrailVal(pt0));
	pt0++;
	RESET_VARIABLE(&TrailTerm(pt0));
	RESET_VARIABLE(&TrailVal(pt0));
	pt0++;
        pt1 += 3;
#endif
      } else {
#ifdef FROZEN_STACKS
        TrailVal(pt0) = TrailVal(pt1);
        TrailTerm(pt0) = d1;
        TrailVal(pt0 + 1) = TrailVal(pt1 + 1);
        TrailTerm(pt0 + 1) = TrailTerm(pt1 + 1);
        pt0 += 2;
        pt1 += 2;
#else
        TrailTerm(pt0 + 1) = TrailTerm(pt1 + 1);
        TrailTerm(pt0) = TrailTerm(pt0 + 2) = d1;
	RESET_VARIABLE(&TrailTerm(pt0+2));
        pt0 += 3;
        pt1 += 3;
#endif /* FROZEN_STACKS */
      }
    } else if (IsPairTerm(d1)) {
      CELL *pt = RepPair(d1);

      else if (IN_BETWEEN(H0, pt, HR) && IsApplTerm(HeadOfTerm(d1))) {
        Term t = HeadOfTerm(d1);
        Functor f = FunctorOfTerm(t);
        if (f == Functorblob) {
          RESET_VARIABLE(&TrailTerm(pt1));
          Int tag = Yap_blob_tag(t);
          GLOBAL_OpaqueHandlers[tag].cut_handler(d1);
        } else if ((*pt & (LogUpdMask | IndexMask)) ==
                   (LogUpdMask | IndexMask)) {
          LogUpdIndex *cl = ClauseFlagsToLogUpdIndex(pt);
#if defined(YAPOR) || defined(THREADS)
          PredEntry *ap = cl->ClPred;
#endif
          int erase;

          LOCK(ap->PELock);
          DEC_CLREF_COUNT(cl);
          cl->ClFlags &= ~InUseMask;
          erase = (cl->ClFlags & (DirtyMask | ErasedMask)) && !(cl->ClRefCount);
          if (erase) {
            /* at this point, we are the only ones accessing the clause,
               hence we don't need to have a lock it */
            if (cl->ClFlags & ErasedMask)
              Yap_ErLogUpdIndex(cl);
            else
              Yap_CleanUpIndex(cl);
          }
          UNLOCK(ap->PELock);
	RESET_VARIABLE(&TrailTerm(pt0));
          pt0++;
	} else {
          TrailTerm(pt0) = d1;
          pt0++;
        }
        pt1++;
      }
      else {
        TrailTerm(pt0) = d1;
        pt0++;
        pt1++;
      }
      ENDD(d1);
    }
    TR = pt0;
  }
#endif /* FROZEN_STACKS */
