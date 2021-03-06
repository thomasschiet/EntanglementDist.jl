using EntanglementDist
using Base.Test

@testset "Basic functions" begin
	rho = wernerState(0.9)
	A = [1 im; im 1]
	@testset "Checks" begin
		@test true == isQuantumState(rho)
		@test false == isQuantumState(eye(2))
		@test true == isHermitian(rho)
		@test false == isHermitian(A)
		@test false == isUnitary(A)
		@test true == isPPT(eye(4)/4,2,2)
		@test false == isPPT(wernerState(0.9),2,2)
	end

	@testset "Simple functions on states" begin
		@test copies(wernerState(1),2) ≈ kron(maxEnt(2), maxEnt(2))
		@test entFidelity(sStateQutrit(1)) ≈ 1
		@test eprFidelity(bellDiagState(0,0,0.3)) ≈ 0.7
		@test eVec(2,1)*eVec(2,1)' + eVec(2,2)*eVec(2,2)' ≈ eye(2)
		@test kron(maxEnt(2),maxEnt(2)) ≈ permutesystems(maxEnt(4),[1,3,2,4], [2,2,2,2])
		# Test partial trace
		n = 4
		rho = maxEnt(n)
		@test eye(n)/n == partialtrace(rho, 1, [n;n])
		@test eye(n)/n == partialtrace(rho, 2, [n;n])
		n = 8
		rho_a = random_densitymatrix(n)
		rho_b = random_densitymatrix(n)
		rho = kron(rho_a, rho_b)
		@test rho_b ≈ partialtrace(rho, 1, [n; n])
		@test rho_a ≈ partialtrace(rho, 2, [n; n])
		#Test partial transpose
		@test partialtranspose(kron(maxEnt(2), maxEnt(2))) ≈ kron(maxEnt(2), maxEnt(2))
		@test partialtranspose(kron(maxEnt(3), maxEnt(2)), 2, [9,4]) ≈ kron(maxEnt(3), maxEnt(2))
		@test partialtrace(partialtranspose(maxEnt(2)),[2],[2,2]) ≈ eye(2)/2
	end
end



@testset "states" begin
	@test bellDiagState(0.25,0.25,0.25) ≈ eye(4)/4
	@test bellDiagState(1,0,0) ≈ maxEnt(2)
	@test sState(0.8) ≈ 0.8 * maxEnt(2) + 0.2 * kron(eVec(2,2),eVec(2,2))*kron(eVec(2,2),eVec(2,2))'
	@test rState(0.8) ≈ 0.8 * maxEnt(2) + 0.2 * kron(eVec(2,1),eVec(2,2))*kron(eVec(2,1),eVec(2,2))'
	@test sStateQutrit(0.8) ≈ 0.8 * maxEnt(3) + 0.2 * kron(eVec(3,1),eVec(3,1))*kron(eVec(3,1),eVec(3,1))'
	@test rStatePhase(0.8, pi) ≈ 0.8 * bell[4,1:4]*bell[4,1:4]' + 0.2 * kron(eVec(2,2),eVec(2,2))*kron(eVec(2,2),eVec(2,2))'
	@test rStateCorrPhase(0, 0.8) ≈ eVec(16,16) * eVec(16,16)'
	@test rStateCorrPhaseCopies(0, 3) ≈ eVec(64,64) * eVec(64,64)'
	@test wernerState(1) ≈ maxEnt(2)
	@test wernerState(0) ≈ eye(4)/4
	@test maxEnt(4)≈ maxEntVec(4)*maxEntVec(4)'
	@test trace(bellDiagState(0.25,0.25,0.25)) ≈ 1
	@test trace(maxEnt(4)) ≈ 1
	@test trace(sState(0.8)) ≈ 1
	@test trace(rState(0.8)) ≈ 1
	@test trace(sStateQutrit(0.8)) ≈ 1
	@test trace(rStatePhase(0.8, pi)) ≈ 1
	@test trace(rStateCorrPhase(0.6, 0.8)) ≈ 1
	@test trace(rStateCorrPhaseCopies(0.4, 3)) ≈ 1
	@test abs(det(random_unitary(3))) ≈ 1
	@test trace(random_densitymatrix(4)) ≈ 1
	@test true == isUnitary(random_unitary(4))
	@test true == isQuantumState(random_densitymatrix(4))
end

@testset "Protocols" begin
	#DEJMPS and BBPSSW cannot create entangled state if the initial fidelity is < 0.5.
	@test DEJMPSParam(bellDiagState(0.4,0.3,0.1))[1] <= 0.5
	@test BBPSSWParam(bellDiagState(0.4,0.3,0.1))[1] <= 0.5
	@test BBPSSWParam(0.6)[1] > 0.6
	#test EPL on rStateCorrPhase:
	@test EPLParam(0.4,0.8)[1] ≈ EPLParam(sortAB(rStateCorrPhase(0.4,0.8),2,2))[1]
	@test EPLParam(0.4,0.8)[2] ≈ EPLParam(sortAB(rStateCorrPhase(0.4,0.8),2,2))[2]
end

@testset "Relaxations" begin
	# Test PPT Relax - no improvements should be possible when demanding success probability 1
	rho = wernerState(0.9);
	initF = entFidelity(rho);
	(problem,F,psucc) = pptRelax(rho,2,2,2,1);
	@test round(F,3) == round(initF,3)

	# Similarly, no improvement for 2 copies
	rho = maxEnt(2);
	initF = entFidelity(rho);
	(problem,F,psucc) = pptRelaxCopies(rho,2,2,2,2,1);
	@test round(F,3) == round(initF,3)

	# Same for 1 extension
	rho = rState(0.9);
	initF = entFidelity(rho);
	(problem,F,psucc) = pptRelax1Ext(rho,2,2,2,1);
	@test round(F,3) == round(initF,3)

	# or even 2 extension
	(problem,F,psucc) = pptRelax2Ext(rho,2,2,2,1);
	@test round(F,3) == round(initF,3)
end
