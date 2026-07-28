package tn.itvision.betweenthree.content.api;

import java.util.List;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import tn.itvision.betweenthree.content.api.dto.PowerCardDefinitionResponse;
import tn.itvision.betweenthree.content.repository.PowerCardDefinitionRepository;

@RestController
@RequestMapping("/api/v1/power-cards")
public class PowerCardController {

    private final PowerCardDefinitionRepository powerCardDefinitionRepository;

    public PowerCardController(PowerCardDefinitionRepository powerCardDefinitionRepository) {
        this.powerCardDefinitionRepository = powerCardDefinitionRepository;
    }

    @GetMapping
    public List<PowerCardDefinitionResponse> listPowerCards() {
        return powerCardDefinitionRepository.findByActiveTrue().stream()
            .map(PowerCardDefinitionResponse::from)
            .toList();
    }
}
